(: Sample XQuery for updating the audio sensor ID field :)

(: Tell Tethys that all names are within the Tethys namespace.
   This keeps us from having to declare a namespace and add
   information to each element name in a path, e.g.
   Deployment/Id as opposed to ty:Deployment/ty:Id
:)
declare default element namespace "http://tethys.sdsu.edu/schema/1.0";

(: We tell it to replace the value of Number with a new value. Note that the value is a string, so we use quotes :)
for $sensnum in collection("Deployments")/Deployment[Id = "ADRIFT102_MBY"]/Sensors/Audio/Number[.= "856142"]
   return replace value of node $sensnum with "856141"