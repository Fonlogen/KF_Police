// const resourceName = (window as any).GetParentResourceName
//   ? (window as any).GetParentResourceName()
//   : "nui-frame-app";


// // Load the locale data from the JSON file
// try {
//   const data = fs.readFileSync(, 'utf8');
//   localeData = JSON.parse(data);
// } catch (error) {
//   console.error('Error loading locale data:', error);
// }

// /**
//  * Translates a given key based on the loaded locale data.
//  * @param key The key to translate.
//  * @returns The translated string or the key itself if no translation is found.
//  */
// export function translate(key: string): string {
//   return localeData[key] || key;
// }