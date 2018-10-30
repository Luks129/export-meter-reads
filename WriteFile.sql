CREATE OR REPLACE DIRECTORY EXPORT as '/tmp';
GRANT READ ON DIRECTORY EXPORT TO PUBLIC;
GRANT WRITE ON DIRECTORY EXPORT TO PUBLIC;


SET SERVEROUTPUT ON
DECLARE
  l_file    UTL_FILE.FILE_TYPE;
  l_clob    CLOB;
  l_buffer  VARCHAR2(32767);
  l_amount  BINARY_INTEGER := 32767;
  l_pos     INTEGER := 1;
  l_date date := sysdate;
begin 
  for rec in (select UC, XML from BTXML1)
  loop DBMS_XSLPROCESSOR.clob2file(rec.XML, 'EXPORT', rec.UC || '_' || TO_CHAR(sysdate, 'YYYYMMDD') ||'.xml_EIP_orgname2'); end loop;
end;

commit;
