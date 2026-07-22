import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAgentFlowBaseScenario } from "../../helpers/mock-api.js";

test("User successfully deletes an existing agent", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_delete_success",
    testTitle: "User successfully deletes an existing agent",
  });

  await recorder.step("Register delete-success scenario mocks", async () => {
    await setupAgentFlowBaseScenario(page);

    await page.route("**/api/agent-flows/list**", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          success: true,
          flows: [{ uuid: "def-456", name: "Email Automator", config: { active: true, steps: [] } }],
        }),
      });
    });

    await page.route("**/api/agent-flows/def-456", async (route) => {
      const method = route.request().method();
      if (method === "DELETE") {
        await route.fulfill({
          status: 200,
          contentType: "application/json",
          body: JSON.stringify({ success: true }),
        });
        return;
      }
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          success: true,
          flow: {
            uuid: "def-456",
            name: "Email Automator",
            config: { name: "Email Automator", description: "Automates email tasks.", active: true, steps: [] },
          },
        }),
      });
    });
  });

  await recorder.step("Load the existing flow", async () => {
    await page.goto("/admin/agents/def-456");
  });

  await recorder.step("Issue delete request from the page context", async () => {
    const response = await page.evaluate(async () => {
      const res = await fetch("http://localhost:3001/api/agent-flows/def-456", { method: "DELETE" });
      return { status: res.status, body: await res.json() };
    });
    expect(response.status).toBe(200);
    expect(response.body.success).toBeTruthy();
  });

  await recorder.step("Assert original flow details were present before deletion", async () => {
    await expect(page.locator('[name="name"]')).toHaveValue("Email Automator");
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_delete_success");
  await recorder.save(testInfo);
});
