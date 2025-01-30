import os

import boto3
import psycopg2

s3_client = boto3.client("s3")
S3_BUCKET = "cll-s3-bucket"
dyn_client = boto3.client("dynamodb")
lambda_client = boto3.client("lambda")


def lambda_handler(event, context):
    print(context)
    # S3
    object_key = "123.txt"  # replace object key
    file_content = s3_client.get_object(Bucket=S3_BUCKET, Key=object_key)["Body"].read()
    print(file_content)

    # RDS
    try:
        connection = psycopg2.connect(
            user="cllpgadmin",
            password="pgpassword123",
            host=os.environ["PG_HOST"],
            database="cllrdspostgres",
        )
    except psycopg2.OperationalError as e:
        print("Unable to connecto to database.\n{0}".format(e))

    try:
        cursor = connection.cursor()
        cursor.execute("""SELECT * from "accounts" """)
        print("Result: ", cursor.fetchall())
    except psycopg2.OperationalError as e:
        print("Unable to SELECT from db table.\n{0}".format(e))
    finally:
        cursor.close()
        connection.close()

    # dynamoDB
    data = dyn_client.get_item(TableName="cll-dynamodb", Key={"id": {"S": "coralogix"}})
    print(data)

    # SQS
    sqs = boto3.client("sqs")
    # Get the URL of the SQS queue
    queue_url = os.environ["SQS_QUEUE"]
    # Create a sample message
    message = """{
        "id": "1",
        "text": "This is a sample message"
    }"""
    # Send the message to the SQS queue
    response_sqs = sqs.send_message(QueueUrl=queue_url, MessageBody=message)
    # Print the response from SQS
    print(response_sqs)

    # Step Function
    stepfunctions_client = boto3.client("stepfunctions")
    input_payload = '{"IsHelloWorldExample": true}'
    response = stepfunctions_client.start_execution(
        stateMachineArn=os.environ["STEP_ARN"], input=input_payload
    )
    execution_arn = response["executionArn"]
    print(execution_arn)

    # SSM
    ssm_client = boto3.client("ssm")
    response = ssm_client.get_parameter(Name="ruler", WithDecryption=True)
    parameter_value = response["Parameter"]["Value"]
    print(parameter_value)

    # Other Lambda
    lambda_response = lambda_client.invoke(
        FunctionName="cll-lambda-python-2",
        InvocationType="RequestResponse",
    )
    print(lambda_response)
    # Other Node Lambda
    node_lambda_response = lambda_client.invoke(
        FunctionName="cll-lambda-nodejs",
        InvocationType="RequestResponse",
    )
    print("node_lambda_response")
    print(node_lambda_response)
