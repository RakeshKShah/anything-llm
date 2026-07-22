import { test, expect } from "@playwright/test";
import { ExecutionRecorder } from "../../helpers/execution-recorder.js";
import { setupAgentFlowBaseScenario } from "../../helpers/mock-api.js";

test("Agent deletion fails for non-admin users", async ({ page }, testInfo) => {
  const recorder = new ExecutionRecorder({
    testId: "agent_delete_fails_unauthorized",
    testTitle: "Agent deletion fails for non-admin users",
  });

  await recorder.step("Register base system mocks and override auth for non-admin user", async () => {
    await setupAgentFlowBaseScenario(page);

    await page.route("**/api/auth", async (route) => {
      await route.fulfill({
        status: 200,
        contentType: "application/json",
        body: JSON.stringify({
          authenticated: true,
          user: { id: 2, username: "basic-user", role: "user" },
        }),
      });
    });

    await page.route("**/api/experimental/agent-plugins/agent-123", async (route) => {
      if (route.request().method() !== "DELETE") {
        await route.continue();
        return;
      }

      await page.evaluate(() => {
        window.__agentPluginLastDeleteResponse = {
          status: 403,
          body: {
            success: false,
            error: "You do not have permission to delete agents.",
          },
        };
      });

      await route.fulfill({
        status: 403,
        contentType: "application/json",
        body: JSON.stringify({
          success: false,
          error: "You do not have permission to delete agents.",
        }),
      });
    });
  });

  await recorder.step("Open the application", async () => {
    await page.goto("/");
    await expect(page.locator("#root")).toBeAttached();
  });

  await recorder.step("Invoke delete and assert the frontend rejects unauthorized deletion", async () => {
    const result = await page.evaluate(async () => {
      const mod = await import("/src/models/experimental/agentPlugins.js");
      return await mod.default.deletePlugin("agent-123");
    });

    expect(result).toBe(false);
  });

  await recorder.step("Assert forbidden response details", async () => {
    const response = await page.evaluate(() => window.__agentPluginLastDeleteResponse);
    expect(response.status).toBe(403);
    expect(response.body).toEqual({
      success: false,
      error: "You do not have permission to delete agents.",
    });
  });

  console.log("CODEVALID_TEST_ASSERTION_OK:agent_delete_fails_unauthorized");
  await recorder.save(testInfo);
});
