#include "DHT.h"
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

const char *topic_telemetry = "irrigation/device/esp32_01/telemetry";

// --- Hardware ---
#define DHTPIN 15
#define DHTTYPE DHT22
#define POTPIN 34 // Analog ADC1_CH6

DHT dht(DHTPIN, DHTTYPE);
WiFiClientSecure espClient;
PubSubClient client(espClient);

unsigned long lastMsg = 0;
#define MSG_INTERVAL 5000 // Publish every 5 seconds

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

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    String clientId = "ESP32Client-Sensor-";
    clientId += String(random(0xffff), HEX);

    if (client.connect(clientId.c_str(), mqtt_user, mqtt_pass)) {
      Serial.println("connected");
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
  dht.begin();

  // Important for SSL/TLS without a cert bundle in Wokwi/Sim
  espClient.setInsecure();

  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  unsigned long now = millis();
  if (now - lastMsg > MSG_INTERVAL) {
    lastMsg = now;

    // Read Sensors
    float h = dht.readHumidity();
    float t = dht.readTemperature();
    int potValue = analogRead(POTPIN);

    // Map potentiometer value (0-4095) to percentage (0-100)
    // Note: analogRead resolution on ESP32 is 12-bit (0-4095)
    float soilMoisture = map(potValue, 0, 4095, 0, 100);

    if (isnan(h) || isnan(t)) {
      Serial.println("Failed to read from DHT sensor!");
      return;
    }

    // Create JSON Payload
    String payload = "{";
    payload += "\"temperature\": " + String(t, 1) + ",";
    payload += "\"humidity\": " + String(h, 1) + ",";
    payload += "\"soilMoisture\": " + String(soilMoisture, 1);
    payload += "}";

    Serial.print("Publishing message: ");
    Serial.println(payload);
    client.publish(topic_telemetry, payload.c_str());
  }
}
