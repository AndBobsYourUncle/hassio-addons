Google Assistant Webserver
--------------------------
About
--------------------------
A virtual personal assistant developed by Google (text input via webserver). Once running and authenticated, you can send a GET request to http://hassio.local:5000/broadcast_message?message=[MESSAGE] to broadcast a text message to all your Google Assistants.

Community discussion can be found [here](https://community.home-assistant.io/t/community-hass-io-add-on-google-assistant-webserver-broadcast-messages-without-interrupting-music).

Add-on Installation
--------------------------

1. Add the hassio-addons repo to Hassio addons page: https://github.com/AndBobsYourUncle/hassio-addons
2. Follow the [google assistant](https://www.home-assistant.io/addons/google_assistant/) directions from 1-3 including renaming the JSON file and moving it to the /share/ location in your Hassio instance. 
3. Start the addon, and open the web UI (http://[your.hassio.IP]:9324).
4. Click the "authentication" link on the page, and confirm your login with your google account. 
5. Copy the token and paste it into the box in the web UI page (http://[your.hassio.IP]:9324).
6. Click the "connect" button.

Add-on integration
--------------------------
You can add the below to your config.yaml then call notify.google_assistant or notify.google_assistant_command to broadcast a message accross your google homes or send an arbitrary command.

Send Broadcast

```yaml
notify:
  - name: Google Assistant
    platform: rest
    resource: http://[your.hassio.IP]:5000/broadcast_message
```

Send Google Assistant Command

```yaml
notify:
  - name: Google Assistant Command
    platform: rest
    resource: http://[your.hassio.IP]:5000/command?message=google_command
