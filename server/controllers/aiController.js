const { GoogleGenAI } = require("@google/genai");

const DEFAULT_TASK_TAG_COLOR = "orange";
const DEFAULT_SCHEDULE_COLOR = "blue";

function getTodayDateKey() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");

  return `${year}-${month}-${day}`;
}

function getDateKeyLocal(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");

  return `${year}-${month}-${day}`;
}

function dateKeyToLocalDate(dateKey) {
  const [year, month, day] = String(dateKey || "")
    .split("-")
    .map(Number);

  if (!year || !month || !day) {
    return new Date();
  }

  return new Date(year, month - 1, day);
}

function addDays(date, days) {
  const value = new Date(date);
  value.setDate(value.getDate() + days);
  return value;
}

function removeVietnameseTones(value) {
  return String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d")
    .replace(/Đ/g, "D");
}

function normalizeCommonTypingMistakes(value) {
  return String(value || "")
    .replace(/\blcus\b/gi, "lúc")
    .replace(/\blucs\b/gi, "lúc")
    .replace(/\bngayf\b/gi, "ngày")
    .replace(/\bnagyf\b/gi, "ngày")
    .replace(/\bdid\b/gi, "đi");
}

function getPageContext(body) {
  const page = String(body.page || body.currentPage || body.context || "");
  const path = String(body.path || body.pathname || "");
  const source = removeVietnameseTones(`${page} ${path}`).toLowerCase();

  if (source.includes("schedule") || source.includes("lich")) {
    return "schedule";
  }

  if (source.includes("tasks") || source.includes("nhiem vu")) {
    return "tasks";
  }

  return "home";
}

function normalizeYear(value, fallbackYear) {
  if (!value) return fallbackYear;

  const year = Number(value);

  if (Number.isNaN(year)) return fallbackYear;
  if (year < 100) return 2000 + year;

  return year;
}

function parseExplicitDate(text, todayDate) {
  const normalized = removeVietnameseTones(text).toLowerCase();
  const isoMatch = normalized.match(/\b(\d{4})[/-](\d{1,2})[/-](\d{1,2})\b/);

  if (isoMatch) {
    const date = new Date(
      Number(isoMatch[1]),
      Number(isoMatch[2]) - 1,
      Number(isoMatch[3]),
    );

    if (!Number.isNaN(date.getTime())) return date;
  }

  const vnMatch = normalized.match(
    /(?:^|[^\d])(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?(?!\d)/,
  );

  if (!vnMatch) return null;

  const day = Number(vnMatch[1]);
  const month = Number(vnMatch[2]);
  const year = normalizeYear(vnMatch[3], todayDate.getFullYear());

  if (day < 1 || day > 31 || month < 1 || month > 12) return null;

  const date = new Date(year, month - 1, day);

  if (
    date.getFullYear() !== year ||
    date.getMonth() !== month - 1 ||
    date.getDate() !== day
  ) {
    return null;
  }

  return date;
}

function parseWeekday(text) {
  const normalized = removeVietnameseTones(text).toLowerCase();
  const patterns = [
    { day: 0, pattern: /\b(chu\s*nhat|cn|sunday)\b/ },
    { day: 1, pattern: /\b(thu\s*(2|hai)|monday)\b/ },
    { day: 2, pattern: /\b(thu\s*(3|ba)|tuesday)\b/ },
    { day: 3, pattern: /\b(thu\s*(4|tu)|wednesday)\b/ },
    { day: 4, pattern: /\b(thu\s*(5|nam)|thursday)\b/ },
    { day: 5, pattern: /\b(thu\s*(6|sau)|friday)\b/ },
    { day: 6, pattern: /\b(thu\s*(7|bay)|saturday)\b/ },
  ];

  const match = patterns.find((item) => item.pattern.test(normalized));

  return match ? match.day : null;
}

function getNextWeekdayDate(todayDate, weekday) {
  const diff = (weekday - todayDate.getDay() + 7) % 7;
  return addDays(todayDate, diff);
}

function parseDateFromText(text, todayDate) {
  const explicitDate = parseExplicitDate(text, todayDate);

  if (explicitDate) return explicitDate;

  const normalized = removeVietnameseTones(text).toLowerCase();

  if (/\b(hom\s*nay|today)\b/.test(normalized)) {
    return todayDate;
  }

  if (/\b(ngay\s*mai|tomorrow)\b/.test(normalized)) {
    return addDays(todayDate, 1);
  }

  const weekday = parseWeekday(text);

  if (weekday !== null) {
    return getNextWeekdayDate(todayDate, weekday);
  }

  return null;
}

function normalizeTime(hourValue, minuteValue = 0) {
  const hour = Number(hourValue);
  const minute = Number(minuteValue || 0);

  if (
    Number.isNaN(hour) ||
    Number.isNaN(minute) ||
    hour < 0 ||
    hour > 23 ||
    minute < 0 ||
    minute > 59
  ) {
    return null;
  }

  return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}:00`;
}

function addOneHourSql(timeValue) {
  const [hourText, minuteText] = String(timeValue || "09:00:00").split(":");
  const date = new Date();

  date.setHours(Number(hourText || 9), Number(minuteText || 0), 0, 0);
  date.setHours(date.getHours() + 1);

  return normalizeTime(date.getHours(), date.getMinutes()) || "10:00:00";
}

function parseTimeRange(text) {
  const normalized = removeVietnameseTones(text)
    .toLowerCase()
    .replace(/(\d{1,2})\s*(?:h|gio)\s*(\d{1,2})?/g, function (
      _match,
      hour,
      minute,
    ) {
      return `${hour}:${minute || "00"}`;
    });
  const timePart = String.raw`(\d{1,2})(?::\s*(\d{1,2}))?`;
  const rangeRegex = new RegExp(
    `${timePart}\\s*(?:-|den|toi|to)\\s*${timePart}`,
    "i",
  );
  const rangeMatch = normalized.match(rangeRegex);

  if (rangeMatch) {
    const startTime = normalizeTime(rangeMatch[1], rangeMatch[2] || 0);
    const endTime = normalizeTime(rangeMatch[3], rangeMatch[4] || 0);

    if (startTime && endTime) {
      return {
        start_time: startTime,
        end_time: endTime,
        has_end_time: true,
      };
    }
  }

  const singleRegex = new RegExp(`(?:vao\\s*luc|luc|vao|at)\\s*${timePart}`, "i");
  const singleMatch = normalized.match(singleRegex);

  if (!singleMatch) return null;

  const startTime = normalizeTime(singleMatch[1], singleMatch[2] || 0);

  if (!startTime) return null;

  return {
    start_time: startTime,
    end_time: addOneHourSql(startTime),
    has_end_time: false,
  };
}

function parseRepeatUntil(text, todayDate, startDate) {
  const normalized = removeVietnameseTones(text).toLowerCase();
  const dateMatch = normalized.match(
    /(?:keo\s*dai\s*den|lap\s*lai\s*den|den|toi|het)\s*(?:ngay\s*)?(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?/,
  );

  if (dateMatch) {
    const day = Number(dateMatch[1]);
    const month = Number(dateMatch[2]);
    const year = normalizeYear(dateMatch[3], startDate.getFullYear());
    const date = new Date(year, month - 1, day);

    if (!Number.isNaN(date.getTime())) {
      return getDateKeyLocal(date);
    }
  }

  const monthMatches = Array.from(
    normalized.matchAll(/thang\s*(\d{1,2})(?:[/-](\d{2,4}))?/g),
  );

  if (monthMatches.length === 0) return null;

  const lastMatch = monthMatches[monthMatches.length - 1];
  const month = Number(lastMatch[1]);

  if (month < 1 || month > 12) return null;

  let year = normalizeYear(lastMatch[2], startDate.getFullYear());

  if (!lastMatch[2] && month - 1 < startDate.getMonth()) {
    year += 1;
  }

  return getDateKeyLocal(new Date(year, month, 0));
}

function cleanupTitle(value, fallbackTitle) {
  const title = String(value || "")
    .replace(/\b(lúc|luc|at|vào lúc|vao luc)\s*\d{1,2}\s*(?:h|giờ|gio|:)?\s*\d{0,2}/gi, "")
    .replace(/\b\d{1,2}\s*(?:h|giờ|gio|:)\s*\d{0,2}\s*(?:-|đến|dến|den|tới|toi|to)\s*\d{1,2}\s*(?:h|giờ|gio|:)?\s*\d{0,2}/gi, "")
    .replace(/\b(ngày|ngay)\s*\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?/gi, "")
    .replace(/\b(thứ|thu)\s*(hai|ba|tư|tu|năm|nam|sáu|sau|bảy|bay|\d)\b/gi, "")
    .replace(/\b(hôm nay|hom nay|ngày mai|ngay mai|today|tomorrow)\b/gi, "")
    .replace(/\b(và|va)?\s*(kéo dài|keo dai|lặp lại|lap lai|đến|den|tới|toi)\s+.*$/gi, "")
    .replace(/^[\s,.:;-]+|[\s,.:;-]+$/g, "")
    .replace(/\s+/g, " ")
    .trim();

  return title || fallbackTitle;
}

function deriveTitle(text, page) {
  const fallbackTitle = page === "schedule" ? "Lịch mới" : "Nhiệm vụ mới";
  const original = String(text || "").replace(/\s+/g, " ").trim();
  const patterns = [
    /(?:task|nhiệm vụ|nhiem vu)\s*(?:là|la|:)\s*(.+)$/i,
    /(?:thêm|them)\s+(?:cho\s+)?(?:tôi|toi|mình|minh|em)?\s*(?:task|nhiệm vụ|nhiem vu)?\s*(?:là|la|:)?\s*(.+)$/i,
    /(?:tôi|toi|mình|minh|em)?\s*(?:muốn|muon)\s*(?:thêm|them)\s*(?:task|nhiệm vụ|nhiem vu)?\s*(?:là|la|:)?\s*(.+)$/i,
    /(?:tôi|toi|mình|minh|em)?\s*(?:có|co)\s+(.+?)(?=\s+(?:ngày|ngay|thứ|thu|lúc|luc|vào|vao|kéo|keo|\d{1,2}\s*(?:h|:))|$)/i,
    /(?:tôi|toi|mình|minh|em)?\s*(?:cần|can)\s+(.+?)(?=\s+(?:lúc|luc|ngày|ngay|vào|vao|\d{1,2}\s*(?:h|:))|$)/i,
  ];

  const match = patterns
    .map((pattern) => original.match(pattern))
    .find(Boolean);

  return cleanupTitle(match ? match[1] : original, fallbackTitle);
}

function formatHumanTime(sqlTime) {
  return String(sqlTime || "").slice(0, 5);
}

function appendTimeToDescription(description, item) {
  if (!item.start_time) return description || "";

  const start = formatHumanTime(item.start_time);
  const end = item.end_time && item.has_end_time !== false ? formatHumanTime(item.end_time) : "";
  const timeLine = end ? `Thời gian: ${start} - ${end}` : `Thời gian: ${start}`;
  const base = String(description || "").trim();

  if (base.includes(start)) return base;

  return [base, timeLine].filter(Boolean).join("\n");
}

function parseRuleBasedCommand(message, page, today) {
  const normalizedMessage = normalizeCommonTypingMistakes(message);
  const todayDate = dateKeyToLocalDate(today);
  const parsedDate = parseDateFromText(normalizedMessage, todayDate) || todayDate;
  const dateKey = getDateKeyLocal(parsedDate);
  const timeRange = parseTimeRange(normalizedMessage);
  const title = deriveTitle(normalizedMessage, page);

  if (page === "schedule") {
    const repeatUntil = parseRepeatUntil(normalizedMessage, todayDate, parsedDate);

    return {
      type: "schedule",
      items: [
        {
          title,
          description: String(normalizedMessage || "").trim(),
          schedule_date: dateKey,
          start_time: timeRange?.start_time || "09:00:00",
          end_time: timeRange?.end_time || "10:00:00",
          color: DEFAULT_SCHEDULE_COLOR,
          repeat_type: repeatUntil ? "weekly" : null,
          repeat_until: repeatUntil,
        },
      ],
    };
  }

  const item = {
    title,
    description: appendTimeToDescription("", {
      ...(timeRange || {}),
      has_end_time: timeRange?.has_end_time,
    }),
    task_date: dateKey,
    task_type: page === "home" && dateKey !== today ? "future" : "today",
    priority: "normal",
    tag_color: DEFAULT_TASK_TAG_COLOR,
  };

  return {
    type: "tasks",
    items: [item],
  };
}

function safeJsonParse(text) {
  try {
    return JSON.parse(text);
  } catch (error) {
    const match = text.match(/\{[\s\S]*\}/);

    if (!match) {
      throw error;
    }

    return JSON.parse(match[0]);
  }
}

function normalizeSqlTime(value) {
  if (!value) return null;

  const match = String(value).match(/^(\d{1,2})(?::(\d{1,2}))?(?::\d{1,2})?$/);

  if (!match) return null;

  return normalizeTime(match[1], match[2] || 0);
}

function normalizeRepeatType(value) {
  const repeatType = String(value || "").toLowerCase();

  return ["weekly", "monthly", "yearly"].includes(repeatType)
    ? repeatType
    : null;
}

function normalizeAiResult(result, context = {}) {
  const today = context.today || getTodayDateKey();
  const page = context.page || "home";

  if (!result || typeof result !== "object") {
    return {
      type: "unknown",
      items: [],
    };
  }

  if (!["tasks", "schedule", "unknown"].includes(result.type)) {
    result.type = "unknown";
  }

  if (!Array.isArray(result.items)) {
    result.items = [];
  }

  result.items = result.items.map((item) => ({
    title: item.title || "",
    description: item.description || "",
    task_date: item.task_date || null,
    schedule_date: item.schedule_date || null,
    start_time: normalizeSqlTime(item.start_time),
    end_time: normalizeSqlTime(item.end_time),
    task_type: item.task_type || null,
    priority: item.priority || "normal",
    color: item.color || DEFAULT_SCHEDULE_COLOR,
    tag_color: item.tag_color || DEFAULT_TASK_TAG_COLOR,
    repeat_type: normalizeRepeatType(item.repeat_type || item.recurrence),
    repeat_until: item.repeat_until || null,
    repeat_count: item.repeat_count || null,
  }));

  if (["home", "tasks"].includes(page) && result.items.length > 0) {
    result.type = "tasks";
    result.items = result.items.map((item) => {
      const taskDate = item.task_date || item.schedule_date || today;
      const taskType = page === "home" && taskDate !== today ? "future" : "today";

      return {
        ...item,
        description: appendTimeToDescription(item.description, item),
        task_date: taskDate,
        task_type: taskType,
        schedule_date: null,
        start_time: null,
        end_time: null,
        tag_color: item.tag_color || DEFAULT_TASK_TAG_COLOR,
      };
    });
  }

  if (page === "schedule" && result.items.length > 0) {
    result.type = "schedule";
    result.items = result.items.map((item) => {
      const startTime = item.start_time || "09:00:00";

      return {
        ...item,
        schedule_date: item.schedule_date || item.task_date || today,
        start_time: startTime,
        end_time: item.end_time || addOneHourSql(startTime),
        color: item.color || DEFAULT_SCHEDULE_COLOR,
      };
    });
  }

  return result;
}

async function parseFlowlyCommand(req, res) {
  try {
    const { message } = req.body;
    const page = getPageContext(req.body || {});

    if (!message || message.trim() === "") {
      return res.status(400).json({
        message: "Thiếu nội dung chat",
      });
    }

    const today = getTodayDateKey();
    const fallbackResult = parseRuleBasedCommand(message, page, today);

    if (!process.env.GEMINI_API_KEY) {
      return res.json({
        result: normalizeAiResult(fallbackResult, { page, today }),
      });
    }

    const prompt = `
Bạn là bộ phân tích câu lệnh cho app quản lý task/lịch tên Flowly.

Hôm nay là: ${today}
Trang hiện tại người dùng đang đứng: ${page}

Nhiệm vụ của bạn:
- Đọc câu tiếng Việt hoặc tiếng Anh của người dùng.
- Người dùng có thể gõ không dấu hoặc sai nhẹ, ví dụ "lcus" = "lúc", "ngayf" = "ngày".
- Trên trang home: luôn tạo type = "tasks" cho việc trong hôm nay hoặc ngày cụ thể. Nếu có giờ như "lúc 9h50", đưa giờ vào description, không dùng schedule.
- Trên trang tasks: chỉ tạo type = "tasks", title là nội dung task chính, ngày mặc định là hôm nay nếu người dùng không nói ngày.
- Trên trang schedule: tạo type = "schedule" cho lịch/học/hẹn có giờ. Nếu người dùng nói thứ trong tuần và "kéo dài đến tháng 6/tháng 7", trả repeat_type = "weekly" và repeat_until là ngày cuối của tháng cuối cùng được nhắc tới.
- Nếu không hiểu, trả type = "unknown".
- Chỉ trả về JSON hợp lệ, không markdown, không giải thích.

Schema JSON bắt buộc:

Nếu là nhiều task:
{
  "type": "tasks",
  "items": [
    {
      "title": "Tên task",
      "description": "",
      "task_date": "YYYY-MM-DD",
      "task_type": "today hoặc future",
      "priority": "normal",
      "tag_color": "orange"
    }
  ]
}

Nếu là lịch/hẹn có giờ:
{
  "type": "schedule",
  "items": [
    {
      "title": "Tên lịch",
      "description": "Mô tả đầy đủ từ câu người dùng",
      "schedule_date": "YYYY-MM-DD",
      "start_time": "HH:mm:ss",
      "end_time": "HH:mm:ss",
      "color": "blue",
      "repeat_type": "weekly hoặc null",
      "repeat_until": "YYYY-MM-DD hoặc null"
    }
  ]
}

Quy tắc:
- "hôm nay" = ${today}
- Ngày dạng 4/5/2026 là ngày 04 tháng 05 năm 2026 theo kiểu Việt Nam.
- Nếu người dùng ghi ngày dạng 4/5 mà không ghi năm, dùng năm hiện tại.
- Với trang home/tasks, câu có "lúc 9h50", "9:50", "9 giờ 50" vẫn là task, giờ nằm trong description.
- Với trang schedule, câu có "lúc 15h đến 17h" dùng start_time = "15:00:00", end_time = "17:00:00".
- Nếu lịch không có end_time, tự cho end_time sau start_time 1 tiếng.
- Nếu người dùng nói "học tập, đi chơi, đi học" trên trang home/tasks thì tách thành từng task riêng.
- task_type = "today" nếu task_date là hôm nay, ngược lại "future".
- Không hiểu nhầm cụm "làm thêm" thành thao tác thêm; title có thể là "Làm thêm".
- Không tự tạo field ngoài schema.

Câu người dùng:
"${message.trim()}"
`;

    let parsed = normalizeAiResult(fallbackResult, { page, today });

    try {
      const ai = new GoogleGenAI({
        apiKey: process.env.GEMINI_API_KEY,
      });

      const response = await ai.models.generateContent({
        model: "gemini-2.5-flash",
        contents: prompt,
        config: {
          responseMimeType: "application/json",
        },
      });

      const aiParsed = normalizeAiResult(safeJsonParse(response.text), {
        page,
        today,
      });

      if (aiParsed.type !== "unknown" && aiParsed.items.length > 0) {
        parsed = aiParsed;
      }
    } catch (error) {
      console.log("AI provider parse failed, using fallback:", error);
    }

    return res.json({
      result: parsed,
    });
  } catch (error) {
    console.log("AI parse error:", error);

    return res.status(500).json({
      message: "Không phân tích được yêu cầu",
    });
  }
}

module.exports = {
  parseFlowlyCommand,
};
