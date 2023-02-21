import { timeTilRun } from '~/packages_and_registries/container_registry/explorer/utils';

describe('Container registry utilities', () => {
  describe('timeTilRun', () => {
    beforeEach(() => {
      jest.spyOn(Date, 'now').mockImplementation(() => new Date('2063-04-04T00:42:00Z').getTime());
    });

    it('should return a human readable time', () => {
      const result = timeTilRun('2063-04-08T01:44:03Z');

      expect(result).toBe('4 days');
    });

    it('should return an empty string with null times', () => {
      const result = timeTilRun(null);

      expect(result).toBe('');
    });
  });
});
