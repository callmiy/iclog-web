import './main.css';
import { Main } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

const apiUrl = process.env.ELM_APP_API_URL;

const getWebSocketUrl = () => {
  if (!apiUrl) {
    return null;
  }
  // if we are in production, we connect directly to the socket using relative uri
  if (apiUrl === '/api') {
    return '/socket/websocket';
  }

  const httpHost = /https?/.exec(apiUrl)[0];
  const websocketHost = httpHost === 'https' ? 'wss' : 'ws';
  return apiUrl
    .replace(httpHost, websocketHost)
    .replace('/api', '/socket/websocket');
};

const flags = {
  apiUrl,
  websocketUrl: getWebSocketUrl()
};

Main.embed(document.getElementById('root'), flags);

registerServiceWorker();
