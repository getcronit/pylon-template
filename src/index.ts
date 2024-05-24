import {defineService, logger, PylonAPI} from '@cronitio/pylon'

export default defineService({
  Query: {
    hello() {
      return 'Hello, World!'
    }
  }
})

export const configureApp: PylonAPI['configureApp'] = app => {
  logger.info('Configuring app')
}
