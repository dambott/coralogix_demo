import logging
import os
import random

import boto3

# Set up logger
logger = logging.getLogger("coralogix_lambda_tests")
stream_formatter = logging.Formatter(
    "[%(asctime)-12s] - [%(levelname)s] - [%(funcName)s] - %(message)s"
)
stream_handler = logging.StreamHandler()
stream_handler.setFormatter(stream_formatter)
logger.addHandler(stream_handler)
logger.setLevel(logging.DEBUG)


s3_client = boto3.client("s3")
S3_BUCKET = "cll-s3-bucket"
dyn_client = boto3.client("dynamodb")
lambda_client = boto3.client("lambda")


def lambda_handler(event, context):
    # S3
    object_key = "123.txt"  # replace object key
    file_content = s3_client.get_object(Bucket=S3_BUCKET, Key=object_key)["Body"].read()
    print(file_content)

    # RDS
    #   connection = psycopg2.connect(user='postgres', password='bcrew-admin', \
    #        host='bcrew-rds-postgres.cqc6nreng85o.us-east-2.rds.amazonaws.com', database='postgres')
    #   cursor = connection.cursor()
    #   query = "SELECT * from accounts"
    #   cursor.execute(query)
    #   results = cursor.fetchone()
    #   print(results)
    #   cursor.close()
    #   connection.commit()

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
    #    lambda_response = lambda_client.invoke(
    #        FunctionName='bcrew-other-lambda',
    #        InvocationType='Event',
    #    )
    #    print(lambda_response)

    #  Handled exception
    try:
        logger.info("Logger info: throwing AssertionError")
        print("Print: throwing AssertionError")
        assert 0, "This exception is handled"
    except Exception as e:
        logger.error("Logger error: caught exception; e={}".format(e))
        logger.exception("Logger exception: caught exception; e={}".format(e))
        print("Print exception: caught exception; e={}".format(e))

    # 50% unhandled exception
    my_choices = ["fail", "success"]
    my_choice = random.choice(my_choices)
    if my_choice == "fail":
        raise ValueError("Lambda Execution failed with ValueError")
    else:
        print("Print: Lambda function finished success")
