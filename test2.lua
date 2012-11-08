return {
  autolayout=true,
  fileversioncreate="00.10",
  fileversionsave="01.02",
  nodes={
    {
      type="Start",
      children={
        {
          type="Selector",
          children={
            {
              type="Selector",
              children={
                {
                  type="Wait",
                  func="2|function() print('ret true') return true end",
                  children=
                  {
                   {
                    type="Action",
                    func="function() print('azione') return true end"
                   }
                  } 
                },
                {
                  type="Action",
                  func="!print|secondnode"
                }
              }
            }
          }
        } 
      }
    } 
  },
  notes="note per il test tree\
su piu righe\
etc\
etc\
fine",
  title="test tree" 
}