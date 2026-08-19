import React from 'react';
import ReactDOM from 'react-dom/client';
import MdtProvider from './state/MdtProvider';
import App from './pages/App';
import './index.css';

/*
  Punto d'ingresso della NUI.
  ---------------------------------------------------------------------------
  Il vecchio VisibilityProvider e' stato rimosso: nascondeva la UI con
  `visibility: hidden`, quindi tutti i componenti restavano montati e in ascolto
  anche a tablet chiuso. La visibilita' ora la gestisce App, che non rende nulla
  quando il tablet e' chiuso; MdtProvider resta montato perche' deve continuare
  a ricevere bootstrap, contatori e invalidazioni.
*/
ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <MdtProvider>
      <App />
    </MdtProvider>
  </React.StrictMode>,
);
