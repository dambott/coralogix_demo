const AWS = require('aws-sdk')
const lambda = new AWS.Lambda()
const aws = require('aws-sdk')
const s3 = new aws.S3({ apiVersion: '2006-03-01' })

async function callLambda () {
  // params to send to lambda
  const newContext = Buffer.alloc(JSON.stringify({ Custom: { myCustom: 'bla' }, custom: { myCustomLower: 'blaaaa' } }))
  const params = {
    FunctionName: 'cll-lambda-nodejs',
    // FunctionName: 'bcrew-lambda-python',
    InvocationType: 'RequestResponse',
    LogType: 'None',
    Payload: '{}',
    ClientContext: newContext.toString('base64')
  }
  const response = await lambda.invoke(params).promise()
  if (response.StatusCode !== 200) {
    throw new Error('Failed to get response from lambda function')
  }
  return JSON.parse(response.Payload)
}

exports.handler = async function (event, context) {
  console.log('EVENT!!', event)
  console.log('CONTEXT!!', context)
  // S3
  const bucket = 'cll-s3-bucket'
  const key = '123.txt'
  const params = {
    Bucket: bucket,
    Key: key
  }
  const { ContentType } = await s3.getObject(params).promise()
  console.log('CONTENT TYPE:', ContentType)

  // invoke and get info from `process_pdf_invoice`
  const output = await callLambda()
  console.log('output', output)

  const stepArn = process.env.STEP_ARN

  // Step Function
  const stepParams = {
    stateMachineArn: stepArn, /* required */
    input: '{"IsHelloWorldExample": true}'
  }
  const stepFunctions = new aws.StepFunctions()
  const stepFunctionResult = await stepFunctions.startExecution(stepParams).promise()
  console.log(stepFunctionResult)

  // now write the code to save data into database
  return { status: 'saved' }
}
