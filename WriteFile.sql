CREATE OR REPLACE DIRECTORY EXPORT as '/tmp';
GRANT READ ON DIRECTORY EXPORT TO PUBLIC;
GRANT WRITE ON DIRECTORY EXPORT TO PUBLIC;


SET SERVEROUTPUT ON
/*
DECLARE
  l_file    UTL_FILE.FILE_TYPE;
  l_clob    CLOB;
  l_buffer  VARCHAR2(32767);
  l_amount  BINARY_INTEGER := 32767;
  l_pos     INTEGER := 1;
  l_date DATE := sysdate;
*/
BEGIN 
  FOR rec IN (SELECT SDP, XML FROM "ExpMR8" ORDER BY "startDate" ASC) LOOP
    DBMS_XSLPROCESSOR.clob2file(rec.XML, 'EXPORT', rec.SDP || '_' || rec.Meter || '_' || TO_CHAR(rec.startDate, 'YYYY-MM') || '_' || rec.channel || '_' || TO_CHAR(sysdate, 'YYYYMMDD-HH24MISS') ||'.xml_EIP_orgname');
  END LOOP;
END;
COMMIT;
