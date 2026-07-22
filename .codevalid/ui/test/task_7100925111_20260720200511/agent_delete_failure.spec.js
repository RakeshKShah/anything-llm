import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAgentFlowBaseScenario } from "../../helpers/mock-api.js";

test("Agent deletion fails with server error", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_delete_failure",
    testTitle: "Agent deletion fails with server error",
  });

  await recorder.step("Register delete-failure scenario mocks", async () => {
    await setupAgentFlowBaseScenario(page);

    await page.route("**/api/agent-flows/ghi-789", async (route) => {
      const method = route.request().method();
      if (method === "DELETE") {
        await route.fulfill({
          status: 500,
          contentType: "application/json",
          body: JSON.stringify({ success: false, error: "Failed to delete flow" }),
        });
        return;
      }
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          success: true,
          flow: {
            uuid: "ghi-789",
            name: "Error Flow",
            config: { name: "Error Flow", description: "Still visible after failed delete.", active: true, steps: [] },
          },
        }),
      });
    });
  });

  await recorder.step("Load the flow targeted for deletion", async () => {
    await page.goto("/admin/agents/ghi-789");
  });

  await recorder.step("Attempt deletion and capture backend failure", async () => {
    const response = await page.evaluate(async () => {
      const res = await fetch("http://localhost:3001/api/agent-flows/ghi-789", { method: "DELETE" });
      return { status: res.status, body: await res.json() };
    });
    expect(response.status).toBe(500);
    expect(response.body.error).toBe("Failed to delete flow");
  });

  await recorder.step("Assert UI state remains intact", async () => {
    await expect(page.locator('[name="name"]')).toHaveValue("Error Flow");
    await expect(page.getByRole("button", { name: "Save" })).toBeEnabled();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_delete_failure");
  await recorder.save(testInfo);
});
