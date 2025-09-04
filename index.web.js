import { AppRegistry } from 'react-native';
import App from './App.web';

AppRegistry.registerComponent('Pally', () => App);
AppRegistry.runApplication('Pally', {
  rootTag: document.getElementById('root'),
});
