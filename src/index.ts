import { defineService, logger, PylonAPI } from "@getcronit/pylon";
import { prisma } from "./client";

export default defineService({
  Query: {
    posts: async () => {
      return await prisma.post.findMany();
    },
  },
});

export const configureApp: PylonAPI["configureApp"] = (app) => {
  logger.info("Configuring app");
};
