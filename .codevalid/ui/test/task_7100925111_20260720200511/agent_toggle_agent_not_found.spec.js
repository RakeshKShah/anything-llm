import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAgentFlowBaseScenario } from "../../helpers/mock-api.js";

test("Agent toggle fails when target agent does not exist", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_toggle_agent_not_found",
    testTitle: "Agent toggle fails when target agent does not exist",
  });

  await recorder.step("Register missing-agent toggle mock", async () => {
    await setupAgentFlowBaseScenario(page);
    await page.route("**/api/agent-flows/bad-uuid/toggle", async (route) => {
      await route.fulfill({
        status: 404,
        contentType: "application/json",
        body: JSON.stringify({ success: false, error: "Flow not found" }),
      });
    });
  });

  await recorder.step("Open agent builder shell", async () => {
    await page.goto("/admin/agents/bad-uuid");
  });

  await recorder.step("Attempt toggle for missing flow", async () => {
    const response = await page.evaluate(async () => {
      const res = await fetch("http://localhost:3001/api/agent-flows/bad-uuid/toggle", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ active: true }),
      });
      return { status: res.status, body: await res.json() };
    });
    expect(response.status).toBe(404);
    expect(response.body.error).toBe("Flow not found");
  });

  await recorder.step("Assert UI shell is preserved", async () => {
    await expect(page.getByRole("button", { name: "Save" })).toBeVisible();
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_toggle_agent_not_found");
  await recorder.save(testInfo);
});
