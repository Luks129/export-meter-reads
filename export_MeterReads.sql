SET SERVEROUTPUT ON
DECLARE
  lSPD VARCHAR2(100);
  lDeviceID VARCHAR2(100);
  lChannelID VARCHAR2(100);
  lMeasTypeID VARCHAR2(100);
  lExtMeasCode VARCHAR2(100);
  lChannelType VARCHAR2(100);
  lReadTime DATE;
  lReadValue NUMBER;
  lStartDate DATE;-- := TO_DATE('2018-01-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS');
  lEndDate DATE;-- := TO_DATE('2018-01-12 03:00:00', 'YYYY-MM-DD HH24:MI:SS');
  lDateCount DATE;
  lMinDate DATE;
  lMaxDate DATE;
  lThereAreReads INTEGER;
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
 
  --DBMS_LOB.CREATETEMPORARY(v_clob,true);  
				         
  --lMinDate := TO_DATE('2018-06', 'YYYY-MM');
  --lMaxDate := TO_DATE('2018-07', 'YYYY-MM');    
  --lDateCount := TO_DATE(TO_CHAR(lMinDate, 'YYYY-MM'), 'YYYY-MM'); 

  FOR it_data IN(
    SELECT "SDP" S, "Meter" M, "startDate" sDate, "endDate" eDate, "channel" C, "extMeasCode" cC, "channelType" cT
    --INTO lChannelID, lMeasTypeID, lReadTime, lReadValue 
    FROM "ExpMR7") LOOP
  BEGIN
    lSPD := it_data.S;
    lDeviceID := it_data.M;
    lStartDate := it_data.sDate;
    lEndDate := it_data.eDate;
    lChannelID := it_data.C;
    lChannelType := it_data.cT; --'Cumulative Consumption';
    /*
    lMinDate := TO_DATE(TO_CHAR(lStartDate, 'YYYY-MM'), 'YYYY-MM');
    
    IF lEndDate IS NULL
    THEN
      lEndDate := TO_DATE(TO_CHAR(sysdate, 'YYYY-MM'), 'YYYY-MM');
    END IF;

    lMaxDate := TO_DATE(TO_CHAR(lEndDate, 'YYYY-MM'), 'YYYY-MM');
    lDateCount := lMinDate;
    */
    
    IF lChannelType = 'Cumulative Consumption' THEN
    BEGIN
      DBMS_OUTPUT.PUT_LINE('Begin IF');
      SELECT MIN(RR.LOCAL_READ_TIME), MAX(RR.LOCAL_READ_TIME)
      INTO lMinDate, lMaxDate
      FROM REGISTER_READS RR
      WHERE RR.CHANNEL_ID=it_data.C;
      EXCEPTION  -- exception handlers begin
  	    WHEN NO_DATA_FOUND THEN  		
  		    NULL;
    END;
    END IF;
    lMinDate := TO_DATE(TO_CHAR(lMinDate, 'YYYY-MM'), 'YYYY-MM');
    lMaxDate := TO_DATE(TO_CHAR(lMaxDate, 'YYYY-MM'), 'YYYY-MM');
    lDateCount := lMinDate;
    
    /*
    IF lEndDate IS NULL
    THEN
      lEndDate := sysdate;
    END IF;
    */
    DBMS_OUTPUT.PUT_LINE('lDateCount Init = ' || lDateCount || ' lMaxDate Init = ' || lMaxDate);
    DBMS_OUTPUT.PUT_LINE('Begin WHILE');   
	
    WHILE lDateCount <= lMaxDate LOOP
      DBMS_LOB.CREATETEMPORARY(v_clob,true);
      v_xml := '<MeterReadsReplyMessage xmlns="http://www.emeter.com/energyip/amiinterface" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><Header><verb>reply</verb><noun>MeterReads</noun><revision>2</revision><dateTime>' || TO_CHAR(sysdate, 'YYYY-MM-DD HH24:MI:SS') || '</dateTime><source>SOURCE1</source></Header><payload><MeterReading><Meter><mRID>' || it_data.M  || '</mRID><idType>METER_X_ELECTRONIC_ID</idType><pathName>SOURCE1</pathName></Meter><IntervalBlock><readingTypeId>' || it_data.C  || '</readingTypeId>';
      DBMS_LOB.APPEND(v_clob, v_xml);
      
      DBMS_OUTPUT.PUT_LINE('lDateCount BeginOfFile = '||lDateCount);
      
      /*      
      IF lChannelType = 'R' THEN
      
      END IF;
      
      IF lChannelType = 'I' THEN
      
      END IF;
      */
      lThereAreReads := 0;
      FOR it_mudr IN(
        SELECT RR.LOCAL_READ_TIME RRT, RR.CUM_READ RRVALUE, RR.CHANNEL_ID CHID
        FROM REGISTER_READS RR
        WHERE channel_ID=it_data.C
        AND RR.LOCAL_READ_TIME >= lDateCount
        AND RR.LOCAL_READ_TIME < ADD_MONTHS(lDateCount, 1)
        ORDER BY LOCAL_READ_TIME ASC) LOOP
        BEGIN
          --Loop with meter reads
          v_xml := '<IReading><endTime>' || TO_CHAR(it_mudr.RRT, 'YYYY-MM-DD HH24:MI:SS')  || '</endTime><value>' || it_mudr.RRVALUE  || '</value><flags>0</flags></IReading>';
          DBMS_LOB.APPEND(v_clob, v_xml);
          DBMS_OUTPUT.PUT_LINE('LOCAL_READ_TIME = ' || it_mudr.RRT || ' CUM_READ = ' || it_mudr.RRVALUE);
          lThereAreReads := 1;
          
        END;
        END LOOP;
      
      v_xml := '</IntervalBlock></MeterReading></payload></MeterReadsReplyMessage>';
      DBMS_LOB.APPEND(v_clob, v_xml);
	  
      IF lThereAreReads > 0 THEN
        v_xml_insert  := 'INSERT INTO "ExpMR8" ("SDP", "Meter", "startDate", "channel", "XML") VALUES (:1, :1, :1, :1, :1)';
	    EXECUTE IMMEDIATE v_xml_insert USING lSPD, lDeviceID, lDateCount, lChannelID, v_clob;
        COMMIT;
      END IF;
	  
	  lDateCount := ADD_MONTHS(lDateCount, 1);
      DBMS_OUTPUT.PUT_LINE('lDateCount EndOfFile = '||lDateCount);
	  
      DBMS_LOB.FREETEMPORARY(v_clob);

    END LOOP;
        
  END;
  END LOOP;	
END;
--COMMIT;
