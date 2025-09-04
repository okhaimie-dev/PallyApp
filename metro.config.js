const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

/**
 * Metro configuration
 * https://reactnative.dev/docs/metro
 *
 * @type {import('@react-native/metro-config').MetroConfig}
 */
const config = {
  transformer: {
    unstable_allowRequireContext: true,
  },
  resolver: {
    alias: {
      'nativewind': 'nativewind/dist/module',
    },
  },
};

module.exports = mergeConfig(getDefaultConfig(__dirname), config);
