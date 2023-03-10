import { SCAN_CADENCE_OPTIONS } from './settings';

/**
 * Converts a cadence option string into the proper schedule parameter.
 * @param {String} str Cadence option's string representation.
 * @returns {Object} Corresponding schedule parameter.
 */
export const toGraphQLCadence = (str) => {
  if (!str) {
    return {};
  }
  const [unit, duration] = str.split('_');
  return { unit, duration: Number(duration) };
};

/**
 * Converts a schedule parameter into the corresponding string option.
 * @param {Object} obj Schedule paramter.
 * @returns {String} Corresponding cadence option's string representation.
 */
export const fromGraphQLCadence = (obj) => {
  if (!obj?.unit || !obj?.duration) {
    return SCAN_CADENCE_OPTIONS[0].value;
  }
  return `${obj.unit}_${obj.duration}`.toUpperCase();
};

/**
 * Extract unique list of tags from list of edges having
 * node as direct child and possible duplicates among tagLists
 * @param nodes
 * @returns {string[]}
 */
export const getUniqueTagListFromEdges = (nodes) => {
  const tags = nodes.map((node) => node?.tagList).flat();

  return Array.from(new Set(tags));
};
