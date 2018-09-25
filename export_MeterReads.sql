DECLARE
  lSPD NUMBER;
  lDeviceID NUMBER;
  lChannelID NUMBER;
  lMeasTypeID NUMBER;
  lExtMeasCode NUMBER;
  lReadTime DATE;
  lReadValue NUMBER;
  lStartDate DATE := TO_DATE('2018-01-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS');
  lEndDate DATE := TO_DATE('2018-01-12 03:00:00', 'YYYY-MM-DD HH24:MI:SS');
  

  v_xml VARCHAR2(10000);
  v_clob  CLOB;
  v_sql VARCHAR2(4000);
  v_xml_insert  VARCHAR2(4000);
  a_count  NUMBER;
  a_countReads  NUMBER;
BEGIN
  
   v_xml := '';
  
   SELECT COUNT(*) INTO a_count FROM ExpMR8;
   
   IF a_count>0
   THEN
      v_sql := 'TRUNCATE TABLE ExpMR8';
      EXECUTE IMMEDIATE v_sql;            
      COMMIT;
   END IF;
 
	
      /*
      BEGIN     	
      SELECT CHANNEL_ID, DEVICE_ID, READ_TIME, READ_VALUE INTO lChannelID, lDeviceID, lReadTime, lReadValue FROM REGISTER_READ WHERE READ_VALUE=384.261383;        
       EXCEPTION  -- exception handlers begin
  							 WHEN NO_DATA_FOUND THEN  		
  							 NULL;
      END;*/

    DBMS_LOB.CREATETEMPORARY(v_clob,true);  
				         
      
	--Header  
  /*
    v_xml := '<MeterReadsReplyMessage xmlns="http://www.emeter.com/energyip/amiinterface" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><Header><verb>reply</verb><noun>MeterReads</noun><revision>2</revision><dateTime>2013-05-25T17:40:53</dateTime><source>SOURCE1</source></Header><payload><MeterReading><Meter><mRID>' || lDeviceID  || '</mRID><idType>METER_X_ELECTRONIC_ID</idType><pathName>SOURCE1</pathName></Meter><IntervalBlock><readingTypeId>' || lChannelID  || '</readingTypeId><IReading><endTime>' || TO_CHAR(lReadTime, 'YYYY-MM-DD HH24:MI:SS')  || '</endTime><value>' || lReadValue  || '</value><flags>0</flags></IReading></IntervalBlock>';
    DBMS_LOB.APPEND(v_clob, v_xml);
	*/
	--Select Interval Data
	/*
	BEGIN
		SELECT DISTINCT(LI.MEAS_TYPE_ID) MT_ID
		INTO lMeasTypeID
		FROM LP_INTERVALS LI
		WHERE LI.INTERVAL_END_TIME >= lStartDate
		AND LI.INTERVAL_END_TIME <= lEndDate
		AND LI.MEAS_TYPE_ID=153
		ORDER BY CHANNEL_ID, INTERVAL_END_TIME;
		EXCEPTION  -- exception handlers begin
  						 WHEN NO_DATA_FOUND THEN  		
  						 null;
	END;*/
	lMeasTypeID := 153;
	
	--Interval Data readingTypeId
    v_xml := '<IntervalBlock><readingTypeId>' || lMeasTypeID  || '</readingTypeId>';
	DBMS_LOB.APPEND(v_clob, v_xml);

  FOR it_data IN(
    SELECT SDP, Meter, startDate, endDate, channel, extMeasCode, channelType
		--INTO lChannelID, lMeasTypeID, lReadTime, lReadValue 
		FROM ExpMR7)      
		-- EXCEPTION  -- exception handlers begin
		--					 WHEN NO_DATA_FOUND THEN  		
		--				 null
  LOOP
	BEGIN
    v_xml := '<MeterReadsReplyMessage xmlns="http://www.emeter.com/energyip/amiinterface" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><Header><verb>reply</verb><noun>MeterReads</noun><revision>2</revision><dateTime>2013-05-25T17:40:53</dateTime><source>SOURCE1</source></Header><payload><MeterReading><Meter><mRID>' || it_data.Meter  || '</mRID><idType>METER_X_ELECTRONIC_ID</idType><pathName>SOURCE1</pathName></Meter><IntervalBlock><readingTypeId>' || it_data.channel  || '</readingTypeId>';
    DBMS_LOB.APPEND(v_clob, v_xml);
    
    FOR it_mudr IN(
      SELECT LOCAL_READ_TIME RRT, CUM_READ RRVALUE
      FROM REGISTER_READS WHERE channel_ID=id_data.channel         
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
	
      v_xml_insert  := 'INSERT INTO ExpMR8 VALUES (:1, :1 )';
	EXECUTE IMMEDIATE v_xml_insert USING lDeviceID,v_clob;
  END;
	END LOOP;	
	 --End Interval Data
		  
	--Loop with register reads
	
	--Footer

	  
END;

COMMIT;
