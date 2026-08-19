export const ConvertToArray = (data: any) => {
  if (Array.isArray(data)) {
    return data;
  }

  if (data && typeof data === 'object') {
    return Object.keys(data).map((key: any) => data[key]);
  }

  return [];
};

export const toRecordMap = (data: any) => {
  if (!data) {
    return {};
  }

  if (Array.isArray(data)) {
    return data.reduce((acc: Record<string, any>, item: any, index: number) => {
      const key = item?.id ?? item?.citizenId ?? item?.plate ?? index;
      acc[String(key)] = item;
      return acc;
    }, {});
  }

  if (typeof data === 'object') {
    return data;
  }

  return {};
};

export const getRecordList = (data: any) => ConvertToArray(toRecordMap(data));

export const getById = (collection: any, id: any) => {
  if (!collection || id === undefined || id === null) {
    return null;
  }

  const map = toRecordMap(collection);
  if (map[String(id)] || map[id]) {
    return map[String(id)] || map[id];
  }

  return Object.values(map).find((item: any) => (
    String(item?.citizenId) === String(id) ||
    String(item?.id) === String(id) ||
    String(item?.identifier) === String(id) ||
    String(item?.plate) === String(id)
  )) || null;
};

export const safeText = (value: any, fallback = '') => {
  if (value === undefined || value === null) {
    return fallback;
  }

  return String(value);
};

export const shorten = (value: any, length = 50) => {
  const text = safeText(value);
  if (!text) {
    return '';
  }

  return text.length > length ? `${text.substring(0, length)}...` : text;
};

export const StringContainsAny = (str: string, substrings: string[]) => {
  if (typeof str !== 'string') {
    return false;
  }

  return substrings.some((substring) => str.includes(substring));
};
