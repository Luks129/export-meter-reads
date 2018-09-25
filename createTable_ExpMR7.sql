CREATE TABLE "ExpMR7" (
  "SDP" VARCHAR2(255 BYTE),
  "Meter" VARCHAR2(255 BYTE),
  "startDate" DATE,
  "endDate" DATE,
  "channel" NUMBER,
  "channelType" VARCHAR2(255 BYTE),
  "extMeasCode" NUMBER
);


CREATE TABLE "ExpMR8" (
  "SDP" VARCHAR2(50 BYTE), 
  "Meter" VARCHAR2(255 BYTE),
  "startDate" DATE,
  "channel" NUMBER,
  "XML" CLOB
);
