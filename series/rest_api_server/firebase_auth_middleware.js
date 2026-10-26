const admin = require("firebase-admin");

let firebaseApp;

function getFirebaseApp() {
  if (firebaseApp) return firebaseApp;

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (!projectId || !clientEmail || !privateKey) return null;

  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert({
      projectId,
      clientEmail,
      privateKey: privateKey.replace(/\\n/g, "\n"),
    }),
  });

  return firebaseApp;
}

async function requireFirebaseUser(req, res, next) {
  const app = getFirebaseApp();
  if (!app) {
    return res.status(503).json({
      message: "ยังไม่ได้ตั้งค่า Firebase Admin บน server",
    });
  }

  const authorization = req.get("Authorization") || "";
  if (!authorization.startsWith("Bearer ")) {
    return res.status(401).json({
      message: "กรุณาส่ง Firebase ID Token",
    });
  }

  const idToken = authorization.substring("Bearer ".length).trim();

  try {
    req.firebaseUser = await admin.auth(app).verifyIdToken(idToken);
    return next();
  } catch (error) {
    console.error("Firebase token verification failed:", error.message);
    return res.status(401).json({
      message: "Firebase ID Token ไม่ถูกต้องหรือหมดอายุ",
    });
  }
}

module.exports = { requireFirebaseUser };
