require("dotenv").config();

const express = require("express");

const taskRoutes = require("./routes/taskRoutes");
const scheduleRoutes = require("./routes/scheduleRoutes");
const aiRoutes = require("./routes/aiRoutes");

const { getHolidayMap } = require("./utils/holidays");

const app = express();
const PORT = process.env.PORT || 3000;

/* =========================
   CORS
========================= */
const allowedOrigins = [
  "http://localhost:5173",
  "http://ryanle.top",
  "https://ryanle.top",
  "http://www.ryanle.top",
  "https://www.ryanle.top",
];

app.use((req, res, next) => {
  const origin = req.headers.origin;

  console.log("Request origin:", origin || "no-origin");

  if (origin && allowedOrigins.includes(origin)) {
    res.setHeader("Access-Control-Allow-Origin", origin);
    res.setHeader("Vary", "Origin");
  }

  res.setHeader(
    "Access-Control-Allow-Methods",
    "GET,POST,PUT,PATCH,DELETE,OPTIONS",
  );

  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");

  res.setHeader("Access-Control-Allow-Credentials", "true");

  if (req.method === "OPTIONS") {
    return res.sendStatus(204);
  }

  return next();
});

/* =========================
   BODY PARSER
========================= */
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

/* =========================
   API ROUTES
========================= */
app.get("/api/config", (req, res) => {
  return res.json({
    supabaseUrl: process.env.SUPABASE_URL,
    supabasePublishableKey: process.env.SUPABASE_PUBLISHABLE_KEY,
  });
});

app.get("/api/holidays/:year", (req, res) => {
  const year = Number(req.params.year);

  if (!Number.isInteger(year)) {
    return res.status(400).json({
      error: "Invalid year",
    });
  }

  return res.json(getHolidayMap(year));
});

app.use("/api/tasks", taskRoutes);
app.use("/api/schedules", scheduleRoutes);
app.use("/api/ai", aiRoutes);

app.use((req, res) => {
  return res.status(404).json({
    error: "Không tìm thấy API",
  });
});

app.listen(PORT, () => {
  console.log(`Flowly API server is running at http://localhost:${PORT}`);
});
