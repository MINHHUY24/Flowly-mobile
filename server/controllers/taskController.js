function isValidTaskType(taskType) {
  return ["today", "future"].includes(taskType);
}

function isValidTagColor(tagColor) {
  if (/^#[0-9a-fA-F]{6}$/.test(tagColor)) return true;

  return [
    "orange",
    "red",
    "green",
    "blue",
    "purple",
    "cyan",
    "yellow",
    "gray",
  ].includes(tagColor);
}

function isValidTaskStatus(status) {
  return [
    "pending",
    "new",
    "doing",
    "paused",
    "done",
    "completed",
    "cancelled",
    "canceled",
  ].includes(status);
}

async function getTasks(req, res) {
  try {
    const { data, error } = await req.supabase
      .from("tasks")
      .select("*")
      .eq("user_id", req.user.id)
      .order("created_at", { ascending: false });

    if (error) {
      return res.status(400).json({
        error: error.message,
      });
    }

    return res.json({
      tasks: data || [],
    });
  } catch (error) {
    console.log("Get tasks error:", error);

    return res.status(500).json({
      error: "Cannot get tasks",
    });
  }
}

async function createTask(req, res) {
  try {
    const {
      title,
      description,
      task_type,
      task_date,
      status,
      priority,
      tag_color,
    } = req.body;

    if (!title || title.trim() === "") {
      return res.status(400).json({
        error: "Tên nhiệm vụ không được để trống",
      });
    }

    if (!isValidTaskType(task_type)) {
      return res.status(400).json({
        error: "task_type không hợp lệ",
      });
    }

    const safeTagColor = tag_color || "orange";
    const safeStatus = status || "pending";

    if (!isValidTagColor(safeTagColor)) {
      return res.status(400).json({
        error: "Vui lòng chọn thẻ màu hợp lệ",
      });
    }

    if (!isValidTaskStatus(safeStatus)) {
      return res.status(400).json({
        error: "status không hợp lệ",
      });
    }

    const { data, error } = await req.supabase
      .from("tasks")
      .insert({
        user_id: req.user.id,
        title: title.trim(),
        description: description || null,
        task_type,
        task_date: task_date || null,
        priority: priority || "normal",
        tag_color: safeTagColor,
        status: safeStatus,
      })
      .select()
      .single();

    if (error) {
      return res.status(400).json({
        error: error.message,
      });
    }

    return res.status(201).json({
      task: data,
    });
  } catch (error) {
    console.log("Create task error:", error);

    return res.status(500).json({
      error: "Cannot create task",
    });
  }
}

async function updateTask(req, res) {
  try {
    const { id } = req.params;
    const {
      title,
      description,
      task_type,
      task_date,
      status,
      priority,
      tag_color,
    } = req.body;

    const updateData = {
      updated_at: new Date().toISOString(),
    };

    if (title !== undefined) {
      updateData.title = title.trim();
    }

    if (description !== undefined) {
      updateData.description = description || null;
    }

    if (task_type !== undefined) {
      if (!isValidTaskType(task_type)) {
        return res.status(400).json({
          error: "task_type không hợp lệ",
        });
      }

      updateData.task_type = task_type;
    }

    if (task_date !== undefined) {
      updateData.task_date = task_date || null;
    }

    if (status !== undefined) {
      updateData.status = status;
    }

    if (priority !== undefined) {
      updateData.priority = priority || "normal";
    }

    if (tag_color !== undefined) {
      if (!tag_color || !isValidTagColor(tag_color)) {
        return res.status(400).json({
          error: "Thẻ màu không hợp lệ",
        });
      }

      updateData.tag_color = tag_color;
    }

    const { data, error } = await req.supabase
      .from("tasks")
      .update(updateData)
      .eq("id", id)
      .eq("user_id", req.user.id)
      .select()
      .single();

    if (error) {
      return res.status(400).json({
        error: error.message,
      });
    }

    return res.json({
      task: data,
    });
  } catch (error) {
    console.log("Update task error:", error);

    return res.status(500).json({
      error: "Cannot update task",
    });
  }
}

async function deleteTask(req, res) {
  try {
    const { id } = req.params;

    const { error } = await req.supabase
      .from("tasks")
      .delete()
      .eq("id", id)
      .eq("user_id", req.user.id);

    if (error) {
      return res.status(400).json({
        error: error.message,
      });
    }

    return res.json({
      success: true,
    });
  } catch (error) {
    console.log("Delete task error:", error);

    return res.status(500).json({
      error: "Cannot delete task",
    });
  }
}

async function updateTaskStatus(req, res) {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({
        error: "Thiếu status",
      });
    }

    const { data, error } = await req.supabase
      .from("tasks")
      .update({
        status,
        updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .eq("user_id", req.user.id)
      .select()
      .single();

    if (error) {
      return res.status(400).json({
        error: error.message,
      });
    }

    return res.json({
      task: data,
    });
  } catch (error) {
    console.log("Update task status error:", error);

    return res.status(500).json({
      error: "Cannot update task status",
    });
  }
}

module.exports = {
  getTasks,
  createTask,
  updateTask,
  deleteTask,
  updateTaskStatus,
};
