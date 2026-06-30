importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAnlgey9i30a85OBpqERC8QUOMOIlvGVcA",
  authDomain: "schat-aa86b.firebaseapp.com",
  projectId: "schat-aa86b",
  storageBucket: "schat-aa86b.firebasestorage.app",
  messagingSenderId: "1086245508574",
  appId: "1:1086245508574:web:8f4b613f04ed6ce32e794f",
  measurementId: "G-MBW35BFDMD"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Received background message ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png",
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
