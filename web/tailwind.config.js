/** @type {import('tailwindcss').Config} */

/*
  I valori NON sono duplicati qui: Tailwind legge i token CSS di
  src/styles/tokens.css. Cambiare un colore o un raggio si fa in un posto solo.

  Attenzione (causa dei bug U3/U4): Tailwind genera solo le classi che vede come
  stringhe letterali nel sorgente. "bg-" + colore o `w-[${x}px]` non vengono mai
  generate. Nei componenti si usano mappe di classi complete e statiche, oppure
  style={{ }} per i valori davvero dinamici.
*/
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        ui: 'var(--font-ui)',
        num: 'var(--font-numeric)',
      },
      colors: {
        shell: 'var(--bg-shell)',
        chrome: 'var(--bg-chrome)',
        sheet: 'var(--bg-sheet)',
        raised: 'var(--bg-raised)',
        inset: 'var(--bg-inset)',
        tab: 'var(--bg-tab)',
        control: 'var(--bg-control)',
        hover: 'var(--bg-hover)',
        active: 'var(--bg-active)',
        navhover: 'var(--bg-nav-hover)',
        collapse: 'var(--bg-collapse)',
        avatar: 'var(--bg-avatar)',
        fg: {
          DEFAULT: 'var(--fg)',
          strong: 'var(--fg-strong)',
          muted: 'var(--fg-muted)',
          dim: 'var(--fg-dim)',
          nav: 'var(--fg-nav)',
          navhover: 'var(--fg-nav-hover)',
          chrome: 'var(--fg-chrome)',
          head: 'var(--fg-head)',
          collapse: 'var(--fg-collapse)',
        },
        accent: 'var(--accent)',
        critical: 'var(--critical)',
        warning: 'var(--warning)',
        success: 'var(--success)',
        info: 'var(--info)',
        line: {
          DEFAULT: 'var(--line)',
          soft: 'var(--line-soft)',
          perf: 'var(--line-perf)',
          ctrl: 'var(--line-ctrl)',
          inset: 'var(--line-inset)',
        },
      },
      borderRadius: {
        sm: 'var(--r-sm)',
        md: 'var(--r-md)',
        lg: 'var(--r-lg)',
        dot: 'var(--r-dot)',
      },
      spacing: {
        statusbar: 'var(--h-statusbar)',
        nav: 'var(--h-nav)',
        tab: 'var(--h-tab)',
        tabactive: 'var(--h-tab-active)',
        sheethead: 'var(--h-sheet-header)',
        thead: 'var(--h-thead)',
        row: 'var(--h-row)',
        field: 'var(--h-field)',
        radiodock: 'var(--h-radiodock)',
        target: 'var(--h-target)',
        btnsm: 'var(--h-btn-sm)',
        btnmd: 'var(--h-btn-md)',
        btnlg: 'var(--h-btn-lg)',
        sidebar: 'var(--w-sidebar)',
        sidebarmin: 'var(--w-sidebar-collapsed)',
        search: 'var(--w-search)',
      },
      fontSize: {
        /* Scala tipografica del design system. Il minimo assoluto e' 0.75rem
           (12 px) e vale solo per intestazioni di colonna ed etichette di
           gruppo: mai per i dati (sezione 3.3). */
        micro: ['0.7rem', { lineHeight: '1.2' }],
        label: ['0.75rem', { lineHeight: '1.25' }],
        chrome: ['0.78rem', { lineHeight: '1.3' }],
        status: ['0.8rem', { lineHeight: '1.3' }],
        tab: ['0.86rem', { lineHeight: '1.3' }],
        card: ['0.9rem', { lineHeight: '1.35' }],
        nav: ['0.92rem', { lineHeight: '1.35' }],
        data: ['0.95rem', { lineHeight: '1.4' }],
        section: ['1.15rem', { lineHeight: '1.25' }],
      },
    },
  },
  plugins: [],
};
