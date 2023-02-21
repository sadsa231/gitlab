import { escape } from 'lodash';

/**
 * Highlight.js plugin for wrapping nodes with the correct selectors to ensure
 * child-elements are highlighted correctly after we split up the result into chunks and lines.
 *
 * Plugin API: https://github.com/highlightjs/highlight.js/blob/main/docs/plugin-api.rst
 *
 * @param {Object} Result - an object that represents the highlighted result from Highlight.js
 */
const newlineRegex = /\r?\n/;
const generateClassName = (suffix) => (suffix ? `hljs-${escape(suffix)}` : '');
const generateCloseTag = (includeClose) => (includeClose ? '</span>' : '');
const generateHLJSTag = (kind, content = '', includeClose) =>
  `<span class="${generateClassName(kind)}">${escape(content)}${generateCloseTag(includeClose)}`;

const format = (node, kind = '') => {
  let buffer = '';

  if (typeof node === 'string') {
    buffer += node
      .split(newlineRegex)
      .map((newline) => generateHLJSTag(kind, newline, true))
      .join('\n');
  } else if (node.kind || node.sublanguage) {
    const { children } = node;
    if (children.length && children.length === 1) {
      buffer += format(children[0], node.kind);
    } else {
      buffer += generateHLJSTag(node.kind);
      children.forEach((subChild) => {
        buffer += format(subChild, node.kind);
      });
      buffer += `</span>`;
    }
  }

  return buffer;
};

export default (result) => {
  // NOTE: We're using the private Emitter API here as we expect the Emitter API to be publicly available soon (https://github.com/highlightjs/highlight.js/issues/3621)
  // eslint-disable-next-line no-param-reassign, no-underscore-dangle
  result.value = result._emitter.rootNode.children.reduce((val, node) => val + format(node), ''); // Highlight.js expects the result param to be mutated for plugins to work
};
