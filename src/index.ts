import { defineService, logger } from "@cronitio/pylon";

export default defineService(
  {
    Query: {
      hello() {
        return "Hello, World!";
      },
    },
  },
  {
    configureApp(app) {
      logger.info("Configuring app");
      return app;
    },
  }
);
