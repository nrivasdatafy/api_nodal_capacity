export const snakeToCamelCase = (str: string) => {
  if (str[0] === '_') return str;
  return str.replace(/_([a-z])/g, (_, p1) => p1.toUpperCase());
};

export const snakeToCamelTransformer = (objectData: { [key: string]: any }) => {
  const objectKeys = Object.keys(objectData);

  for (const objectKey of objectKeys) {
    const camelizedKey = snakeToCamelCase(objectKey);
    objectData[camelizedKey] = objectData[objectKey];
    if (camelizedKey !== objectKey) {
      delete objectData[objectKey];
    }
  }
};
