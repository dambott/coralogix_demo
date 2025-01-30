console.log('Loading function')
const aws = require('aws-sdk')
const s3 = new aws.S3({ apiVersion: '2006-03-01' })
const ddb = new aws.DynamoDB({ apiVersion: '2012-08-10' })
const sqs = new aws.SQS({ apiVersion: '2012-11-05' })
const ssm = new aws.SSM()

const stepArn = process.env.STEP_ARN
const sqsQueue = process.env.SQS_QUEUE

// Your code goes here
// step function
const stepParams = {
  stateMachineArn: stepArn /* required */,
  input: '{"IsHelloWorldExample": true}'
}
const stepfunctions = new aws.StepFunctions()

exports.handler = async (event, context) => {
  // console.log('Received event:', JSON.stringify(event, null, 2));

  // Get the object from the event and show its content type
  console.log('EVENT!!', JSON.stringify(event, null, 2))
  console.log('CONTEXT!!', JSON.stringify(context, null, 2))
  const bucket = 'cll-s3-bucket'
  const key = '123.txt'
  const params = {
    Bucket: bucket,
    Key: key
  }

  const dynamoParams = {
    TableName: 'cll-dynamodb',
    Key: {
      id: { S: 'coralogix' }
    }
  }

  const sqsParams = {
    // Remove DelaySeconds parameter and value for FIFO queues
    DelaySeconds: 10,
    MessageAttributes: {
      Title: {
        DataType: 'String',
        StringValue: 'The Whistler'
      },
      Author: {
        DataType: 'String',
        StringValue: 'John Grisham'
      },
      WeeksOn: {
        DataType: 'Number',
        StringValue: '6'
      }
    },
    MessageBody:
      'Information about current NY Times fiction bestseller for week of 12/11/2016.',
    QueueUrl: sqsQueue
  }

  try {
    const { ContentType } = await s3.getObject(params).promise()
    console.log('CONTENT TYPE:', ContentType)

    // Call DynamoDB to read the item from the table
    const dynamoResult = await ddb.getItem(dynamoParams).promise()
    console.log('DYNAMO RESULT', dynamoResult)

    const sqsResult = await sqs.sendMessage(sqsParams).promise()

    const stepFunctionResult = await stepfunctions
      .startExecution(stepParams)
      .promise()

    console.log(stepFunctionResult)
    console.log('SQS RESULT', sqsResult)

    const { Client } = require('pg')

    const pgHost = process.env.PG_HOST

    const client = new Client({
      user: 'cllpgadmin',
      host: pgHost,
      password: 'pgpassword123',
      database: 'cllrdspostgres',
      port: 5432
    })
    await client.connect()

    try {
      const res = await client.query('SELECT * from accounts')
      console.log(res) // Hello world!
      await client.end()
    } catch (e) {
      console.log(e)
    }

    // SSM
    const param = await ssm
      .getParameter({ Name: 'ruler', WithDecryption: true })
      .promise()
    const paramValue = param.Parameter.Value
    console.log(`Parameter value: ${paramValue}`)

    // exception part
    const randomNumber = Math.random()
    if (randomNumber < 0.5) {
      console.log('Lambda Execution was successful}')
    } else {
      throw new Error(
        `Lambda Execution failed with Exception - randomNumber ${randomNumber}`
      )
    }

    return { statusCode: 200, body: ContentType }
  } catch (err) {
    console.log(err.message)
    // const message = `Error getting object ${key} from bucket ${bucket}. Make sure they exist and your bucket is in the same region as this function.`;
    // console.log(message);
    return { statusCode: 500, body: err.message, err }
  }
}
