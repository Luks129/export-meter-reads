INSERT INTO EMAPP."ExpMR7"
("SDP", "Meter", "startDate", "endDate", "channel", "extMeasCode", "channelType")
SELECT 
       S.UDC_ID SDP,  
       M.UDC_ID MEDIDOR,  
      --SM.type_Status,  
      SM.EFF_START_TIME, 
      SM.EFF_END_TIME, 
      --M.status , 
      chnl.channel_id,    
  
      decode(prd.desc_text,'Register, KWH','KWH Register','Register, KVARH','KVARH Register') as extMeasCode, 
      prd.desc_text as channel_type 
       
       
FROM SDP S,  
     sdp_meter_rel SM,   
     METER M,        
/*    (SELECT   
            S.UDC_ID SDP,  
            MAX(SM.EFF_START_TIME) FECHA_MAXIMA  
    FROM  SDP S,  
          SDP_METER_REL SM,   
          METER M,  
          METER_PARAM MP     
    WHERE   1=1  
            AND mp.meter_id = m.meter_id   
            AND mp.name = 'Program Id'  
            and SM.eff_end_time is null 
            AND mp.eff_end_time is null  
            AND M.METER_ID = sm.meter_id    
            AND S.SDP_ID =  sm.SDP_ID   
            
    GROUP BY    S.UDC_ID) MAX_FECHA ,*/ 
    channel chnl, 
    siebel.s_prod_int  prd, 
    meter_param mp 
  
    
WHERE   1=1  
             
        AND M.METER_ID = sm.meter_id    
        AND S.SDP_ID =  sm.SDP_ID 
        AND M.METER_ID = mp.MeteR_id 
        AND SM.meter_id = mp.MeteR_id 
        and mp.name = 'Marca' 
        and mp.value = 'COMPLANT' 
        and mp.status = 'Active' 
        
        
        AND prd.row_id = chnl.channel_type_id 
       
        AND  chnl.service_point_id = s.sdp_id 
      
       
      
      
          
order by 1,4;
