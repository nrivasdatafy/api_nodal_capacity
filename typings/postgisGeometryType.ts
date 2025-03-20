export enum PostgisGeometryValues {
  //Basic= {
  ST_Point = 'ST_Point',
  ST_LineString = 'ST_LineString',
  ST_Polygon = 'ST_Polygon',
  ST_MultiPoint = 'ST_MultiPoint',
  ST_MultiLineString = 'ST_MultiLineString',
  ST_MultiPolygon = 'ST_MultiPolygon',
  ST_GeometryCollection = 'ST_GeometryCollection',

  //Tridimensional= {
  ST_PointZ = 'ST_PointZ',
  ST_LineStringZ = 'ST_LineStringZ',
  ST_PolygonZ = 'ST_PolygonZ',
  ST_MultiPointZ = 'ST_MultiPointZ',
  ST_MultiLineStringZ = 'ST_MultiLineStringZ',
  ST_MultiPolygonZ = 'ST_MultiPolygonZ',
  ST_GeometryCollectionZ = 'ST_GeometryCollectionZ',

  //metricM= {
  ST_PointM = 'ST_PointM',
  ST_LineStringM = 'ST_LineStringM',
  ST_PolygonM = 'ST_PolygonM',
  ST_MultiPointM = 'ST_MultiPointM',
  ST_MultiLineStringM = 'ST_MultiLineStringM',
  ST_MultiPolygonM = 'ST_MultiPolygonM',
  ST_GeometryCollectionM = 'ST_GeometryCollectionM',

  //TridimensinalMetricZM= {
  ST_PointZM = 'ST_PointZM',
  ST_LineStringZM = 'ST_LineStringZM',
  ST_PolygonZM = 'ST_PolygonZM',
  ST_MultiPointZM = 'ST_MultiPointZM',
  ST_MultiLineStringZM = 'ST_MultiLineStringZM',
  ST_MultiPolygonZM = 'ST_MultiPolygonZM',
  ST_GeometryCollectionZM = 'ST_GeometryCollectionZM',

  //Curved= {
  ST_CircularString = 'ST_CircularString',
  ST_CompoundCurve = 'ST_CompoundCurve',
  ST_CurvePolygon = 'ST_CurvePolygon',
  ST_MultiCurve = 'ST_MultiCurve',
  ST_MultiSurface = 'ST_MultiSurface',

  //Triangles= {
  ST_Triangle = 'ST_Triangle',

  //Surface= {
  ST_PolyhedralSurface = 'ST_PolyhedralSurface',
  ST_TIN = 'ST_TIN',

  //Text= {
  ST_Geography = 'ST_Geography'
}

export type PostgisGeometryType =
  (typeof PostgisGeometryValues)[keyof typeof PostgisGeometryValues];
