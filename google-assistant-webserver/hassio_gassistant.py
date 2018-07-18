"""Hass.IO Google Assistant."""
import json
import sys
from pathlib import Path

import os
import logging

import click
import google.auth.transport.grpc
import google.auth.transport.requests
import google.oauth2.credentials

from google.assistant.embedded.v1alpha2 import (
    embedded_assistant_pb2,
    embedded_assistant_pb2_grpc
)

try:
    from . import (
        assistant_helpers
    )
except (SystemError, ImportError):
    import assistant_helpers

from flask import Flask, request, jsonify
from flask_restful import Resource, Api

app = Flask(__name__)
api = Api(app)

ASSISTANT_API_ENDPOINT = 'embeddedassistant.googleapis.com'
DEFAULT_GRPC_DEADLINE = 60 * 3 + 5
PLAYING = embedded_assistant_pb2.ScreenOutConfig.PLAYING

class BroadcastMessage(Resource):
    def get(self):
        message = request.args.get('message', default = 'This is a test!')
        text_query = 'broadcast '+message
        response_text, response_html = assistant.assist(text_query=text_query)
        logging.debug(response_text)
        return {'status': 'OK'}

api.add_resource(BroadcastMessage, '/broadcast_message')

class Command(Resource):
    def get(self):
        message = request.args.get('message', default = 'This is a test!')
        response_text, response_html = assistant.assist(text_query=message)
        logging.debug(response_text)
        return {'status': 'OK'}

api.add_resource(Command, '/command')


class GoogleTextAssistant(object):
    """Sample Assistant that supports text based conversations.

    Args:
      language_code: language for the conversation.
      device_model_id: identifier of the device model.
      device_id: identifier of the registered device instance.
      display: enable visual display of assistant response.
      channel: authorized gRPC channel for connection to the
        Google Assistant API.
      deadline_sec: gRPC deadline in seconds for Google Assistant API call.
    """

    def __init__(self, language_code, device_model_id, device_id,
                 display, channel, deadline_sec):
        self.language_code = language_code
        self.device_model_id = device_model_id
        self.device_id = device_id
        self.conversation_state = None
        # Force reset of first conversation.
        self.is_new_conversation = True
        self.display = display
        self.assistant = embedded_assistant_pb2_grpc.EmbeddedAssistantStub(
            channel
        )
        self.deadline = deadline_sec

    def __enter__(self):
        return self

    def __exit__(self, etype, e, traceback):
        if e:
            return False

    def assist(self, text_query):
        """Send a text request to the Assistant and playback the response.
        """
        def iter_assist_requests():
            config = embedded_assistant_pb2.AssistConfig(
                audio_out_config=embedded_assistant_pb2.AudioOutConfig(
                    encoding='LINEAR16',
                    sample_rate_hertz=16000,
                    volume_percentage=0,
                ),
                dialog_state_in=embedded_assistant_pb2.DialogStateIn(
                    language_code=self.language_code,
                    conversation_state=self.conversation_state,
                    is_new_conversation=self.is_new_conversation,
                ),
                device_config=embedded_assistant_pb2.DeviceConfig(
                    device_id=self.device_id,
                    device_model_id=self.device_model_id,
                ),
                text_query=text_query,
            )
            # Continue current conversation with later requests.
            self.is_new_conversation = False
            if self.display:
                config.screen_out_config.screen_mode = PLAYING
            req = embedded_assistant_pb2.AssistRequest(config=config)
            # This can be used to output the assistant request
            # assistant_helpers.log_assist_request_without_audio(req)
            yield req

        text_response = None
        html_response = None
        for resp in self.assistant.Assist(iter_assist_requests(),
                                          self.deadline):
            # This can be used to output the assistant response
            # assistant_helpers.log_assist_response_without_audio(resp)
            if resp.screen_out.data:
                html_response = resp.screen_out.data
            if resp.dialog_state_out.conversation_state:
                conversation_state = resp.dialog_state_out.conversation_state
                self.conversation_state = conversation_state
            if resp.dialog_state_out.supplemental_display_text:
                text_response = resp.dialog_state_out.supplemental_display_text
        return text_response, html_response

if __name__ == '__main__':
    global assistant

    cred_json = Path(sys.argv[1])

    # open credentials
    with cred_json.open('r') as data:
        credentials = google.oauth2.credentials.Credentials(token=None, **json.load(data))
        http_request = google.auth.transport.requests.Request()
        credentials.refresh(http_request)

    # Create an authorized gRPC channel.
    grpc_channel = google.auth.transport.grpc.secure_authorized_channel(
        credentials, http_request, ASSISTANT_API_ENDPOINT)

    logging.basicConfig(level=logging.DEBUG)

    # Create the text assistant
    assistant = GoogleTextAssistant('en-US', 'HA_GA', 'HA_GA_TEXT_SERVER',
                             True, grpc_channel, DEFAULT_GRPC_DEADLINE)
    app.run(host='0.0.0.0')
