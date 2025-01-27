require("dotenv").config();
const projectId = process.env.PROJECT_ID || "test-notification-app-84465";
console.log("Project ID:", projectId);

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { CloudTasksClient } = require("@google-cloud/tasks");

admin.initializeApp();

const client = new CloudTasksClient();

// Function to schedule a notification
exports.scheduleNotification = functions.https.onRequest(async (req, res) => {
  const { title, body, scheduledTime, token } = req.body;
  const scheduleDate = new Date(scheduledTime);
  const queue = "notification-queue";
  const location = "us-central1";
  const url = `https://${location}-${projectId}.cloudfunctions.net/sendNotification`;

  const task = {
    httpRequest: {
      httpMethod: "POST",
      url,
      body: Buffer.from(JSON.stringify({ title, body, token })).toString(
        "base64"
      ),
      headers: {
        "Content-Type": "application/json",
      },
    },
    scheduleTime: {
      seconds: scheduleDate.getTime() / 1000,
    },
  };

  try {
    const [response] = await client.createTask({
      parent: client.queuePath(projectId, location, queue),
      task: task,
    });

    console.log(`Created task ${response.name}`);
    res.status(200).send("Notification scheduled");
  } catch (error) {
    console.error("Error scheduling task:", error);
    res.status(500).send("Failed to schedule notification");
  }
});

// Function to send the notification
exports.sendNotification = functions.https.onRequest(async (req, res) => {
  const { title, body, token } = req.body;

  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: token,
  };

  try {
    await admin.messaging().send(message);
    console.log("Successfully sent message:", message);
    res.status(200).send("Notification sent successfully");
  } catch (error) {
    console.error("Error sending message:", error);
    res.status(500).send("Failed to send notification");
  }
});
