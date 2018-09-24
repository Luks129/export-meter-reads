DECLARE
  lSPD NUMBER;
  lDeviceID number;
  lChannelID number;
  lMeasTypeID number;
  lExtMeasCode number;
  lReadTime date;
  lReadValue number;
  lStartDate date := TO_DATE('2018-01-12 00:00:00', 'YYYY-MM-DD HH24:MI:SS');
  lEndDate DATE := TO_DATE('2018-01-12 03:00:00', 'YYYY-MM-DD HH24:MI:SS');
  

  v_xml           VARCHAR2(10000);
  v_blob          clob;
  v_sql           VARCHAR2(4000);
  v_xml_insert           VARCHAR2(4000);
  a_count number;
  a_countReads number;
BEGIN
  
   v_xml               := '';
  
   SELECT COUNT(*) INTO a_count FROM BTXML1;
   
   IF a_count>0
   THEN
      v_sql := 'TRUNCATE TABLE BTXML1';
      EXECUTE IMMEDIATE v_sql;            
      COMMIT;
   END IF;
 
	
 
      BEGIN     	
      SELECT CHANNEL_ID, DEVICE_ID, READ_TIME, READ_VALUE INTO lChannelID, lDeviceID, lReadTime, lReadValue FROM REGISTER_READ WHERE READ_VALUE=384.261383;        
       EXCEPTION  -- exception handlers begin
  							 WHEN NO_DATA_FOUND THEN  		
  							 null;
      END;

    DBMS_LOB.CREATETEMPORARY(v_blob,true);  
				         
      
	--Header  
    v_xml := '<MeterReadsReplyMessage xmlns="http://www.emeter.com/energyip/amiinterface" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><Header><verb>reply</verb><noun>MeterReads</noun><revision>2</revision><dateTime>2013-05-25T17:40:53</dateTime><source>SOURCE1</source></Header><payload><MeterReading><Meter><mRID>' || lDeviceID  || '</mRID><idType>METER_X_ELECTRONIC_ID</idType><pathName>SOURCE1</pathName></Meter><IntervalBlock><readingTypeId>' || lChannelID  || '</readingTypeId><IReading><endTime>' || TO_CHAR(lReadTime, 'YYYY-MM-DD HH24:MI:SS')  || '</endTime><value>' || lReadValue  || '</value><flags>0</flags></IReading></IntervalBlock>';
	DBMS_LOB.APPEND(v_blob, v_xml);
	
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
	DBMS_LOB.APPEND(v_blob, v_xml);

  FOR it_data IN(
    SELECT SDP, Meter, startDate, endDate, channel, extMeasCode
		--INTO lChannelID, lMeasTypeID, lReadTime, lReadValue 
		FROM TABLE_DATA TD)      
		-- EXCEPTION  -- exception handlers begin
		--					 WHEN NO_DATA_FOUND THEN  		
		--				 null
  LOOP
	BEGIN
    
    FOR it_mudr IN (
      SELECT * FROM MUDR WHERE channel_ID=id_data.channel         
    
	--Loop with meter reads
			v_xml := '<IReading><endTime>' || TO_CHAR(it_reads.IET, 'YYYY-MM-DD HH24:MI:SS')  || '</endTime><value>' || it_reads.LPVALUE  || '</value><flags>0</flags></IReading>';
			DBMS_LOB.APPEND(v_blob, v_xml);
		END;
	  END LOOP;	
	 --End Interval Data
		  
	--Loop with register reads
	
	--Footer
	v_xml := '</IntervalBlock></MeterReading></payload></MeterReadsReplyMessage>';
	DBMS_LOB.APPEND(v_blob, v_xml);
	
	v_xml_insert  := 'INSERT INTO BTXML1 VALUES (:1, :1 )';
	EXECUTE IMMEDIATE v_xml_insert USING lDeviceID,v_blob;
	  
END;

COMMIT;
