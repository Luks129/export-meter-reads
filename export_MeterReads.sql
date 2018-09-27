DECLARE
  lSPD VARCHAR2(10000);
  lDeviceID VARCHAR2(10000);
  lChannelID VARCHAR2(10000);
  lMeasTypeID VARCHAR2(10000);
  lExtMeasCode VARCHAR2(10000);
  lReadTime DATE;
  lReadValue NUMBER;
  lStartDate DATE;-- := TO_DATE('2018-01-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS');
  lEndDate DATE := TO_DATE('2018-01-12 03:00:00', 'YYYY-MM-DD HH24:MI:SS');
  

  v_xml VARCHAR2(10000);
  v_clob  CLOB;
  v_sql VARCHAR2(4000);
  v_xml_insert  VARCHAR2(4000);
  a_count  NUMBER;
  a_countReads  NUMBER;
BEGIN
  
  v_xml := '';
  
  SELECT COUNT(*) INTO a_count FROM "ExpMR8";
   
  IF a_count>0
  THEN
      v_sql := 'TRUNCATE TABLE "ExpMR8"';
      EXECUTE IMMEDIATE v_sql;            
      COMMIT;
  END IF;
 
  DBMS_LOB.CREATETEMPORARY(v_clob,true);  
				         
      

  FOR it_data IN(
    SELECT "SDP" S, "Meter" M, "startDate" sDate, "endDate" eDate, "channel" C, "extMeasCode" cC, "channelType" cT
    --INTO lChannelID, lMeasTypeID, lReadTime, lReadValue 
  FROM "ExpMR7")      

  LOOP
  BEGIN
    lSPD := it_data.S;
    lDeviceID := it_data.M;
    lStartDate := it_data.sDate;
    lChannelID := it_data.C;
    
    v_xml := '<MeterReadsReplyMessage xmlns="http://www.emeter.com/energyip/amiinterface" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><Header><verb>reply</verb><noun>MeterReads</noun><revision>2</revision><dateTime>2013-05-25T17:40:53</dateTime><source>SOURCE1</source></Header><payload><MeterReading><Meter><mRID>' || it_data.M  || '</mRID><idType>METER_X_ELECTRONIC_ID</idType><pathName>SOURCE1</pathName></Meter><IntervalBlock><readingTypeId>' || it_data.C  || '</readingTypeId>';
    DBMS_LOB.APPEND(v_clob, v_xml);
    
    FOR it_mudr IN(
      SELECT RR.LOCAL_READ_TIME RRT, RR.CUM_READ RRVALUE, RR.CHANNEL_ID CHID
      FROM REGISTER_READS RR WHERE channel_ID=it_data.C         
      ORDER BY LOCAL_READ_TIME DESC)
      
      LOOP
      BEGIN
        --Loop with meter reads
        v_xml := '<IReading><endTime>' || TO_CHAR(it_mudr.RRT, 'YYYY-MM-DD HH24:MI:SS')  || '</endTime><value>' || it_mudr.RRVALUE  || '</value><flags>0</flags></IReading>';
        DBMS_LOB.APPEND(v_clob, v_xml);
      END;
      END LOOP;
    	
    v_xml := '</IntervalBlock></MeterReading></payload></MeterReadsReplyMessage>';
    DBMS_LOB.APPEND(v_clob, v_xml);
	
    v_xml_insert  := 'INSERT INTO "ExpMR8" ("XML") VALUES (:1)';
	--EXECUTE IMMEDIATE v_xml_insert USING lSPD, lDeviceID, lStartDate, lChannelID,  v_clob;
	EXECUTE IMMEDIATE v_xml_insert USING v_clob;
  END;
  END LOOP;	
END;
--COMMIT;
