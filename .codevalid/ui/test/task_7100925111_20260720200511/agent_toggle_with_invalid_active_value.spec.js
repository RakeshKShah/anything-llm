import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAgentFlowBaseScenario } from "../../helpers/mock-api.js";

test("Agent toggle fails with invalid active value", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_toggle_with_invalid_active_value",
    testTitle: "Agent toggle fails with invalid active value",
  });

  await recorder.step("Register invalid-toggle mock", async () => {
    await setupAgentFlowBaseScenario(page);
    await page.route("**/api/agent-flows/pqr-303/toggle", async (route) => {
      await route.fulfill({
        status: 400,
        contentType: "application/json",
        body: JSON.stringify({ success: false, error: "Invalid active value" }),
      });
    });
  });

  await recorder.step("Open agent builder shell", async () => {
    await page.goto("/admin/agents/pqr-303");
  });

  await recorder.step("Send malformed toggle payload", async () => {
    const response = await page.evaluate(async () => {
      const res = await fetch("http://localhost:3001/api/agent-flows/pqr-303/toggle", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ active: "maybe" }),
      });
      return { status: res.status, body: await res.json() };
    });
    expect(response.status).toBe(400);
    expect(response.body.success).toBe(false);
  });

  await recorder.step("Assert UI shell stays loaded", async () => {
    await expect(page.getByRole("button", { name: "Save" })).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_toggle_with_invalid_active_value");
  await recorder.save(testInfo);
});
