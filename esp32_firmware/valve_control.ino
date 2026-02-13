#include <PubSubClient.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>

// --- Configuration ---
const char *ssid = "Wokwi-GUEST";
const char *password = "";

const char *mqtt_server = "003405b159a641e2bed741f8db2e0344.s1.eu.hivemq.cloud";
const int mqtt_port = 8883;
const char *mqtt_user = "mgharsal";
const char *mqtt_pass = "Anzb123.";

const char *topic_command = "irrigation/device/esp32_01/command";

// --- Hardware ---
#define PUMP_LED_PIN 2 // Built-in LED usually, or external connected to GPIO 2

WiFiClientSecure espClient;
PubSubClient client(espClient);

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

void callback(char *topic, byte *payload, unsigned int length) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");

  String message = "";
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.println(message);

  // Parse JSON manually or just look for keywords for simplicity
  if (message.indexOf("PUMP_ON") > 0) {
    digitalWrite(PUMP_LED_PIN, HIGH);
    Serial.println("PUMP TURNED ON");
  } else if (message.indexOf("PUMP_OFF") > 0) {
    digitalWrite(PUMP_LED_PIN, LOW);
    Serial.println("PUMP TURNED OFF");
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    String clientId = "ESP32Client-Actuator-";
    clientId += String(random(0xffff), HEX);

    if (client.connect(clientId.c_str(), mqtt_user, mqtt_pass)) {
      Serial.println("connected");
      client.subscribe(topic_command);
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(PUMP_LED_PIN, OUTPUT);
  digitalWrite(PUMP_LED_PIN, LOW); // Start OFF

  // Important for SSL/TLS without a cert bundle
  espClient.setInsecure();

  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
}
