import NewExpr,NewExprVal,ExprIndex,ExprToString,Items from require "Data.API.Expression"

for item in *{
	{
		Name:"SensorName"
		Text:"Sensor Name"
		Type:"SensorName"
		MultiLine:false
		TypeIgnore:false
		Group:"Special"
		Desc:"A name for sensor."
		CodeOnly:true
		ToCode:=> "\"#{ @[2] }\""
		Create:NewExprVal "InvalidName"
		Args:false
		__index:ExprIndex
		__tostring:ExprToString
	}
	{
		Name:"SensorByName"
		Text:"Sensor"
		Type:"Sensor"
		MultiLine:false
		TypeIgnore:false
		Group:"Sensor"
		Desc:"Get sensor [SensorName] from scene."
		CodeOnly:false
		ToCode:=> "Sensor( #{ @[2] } )"
		Create:NewExpr "SensorName"
		Args:false
		__index:ExprIndex
		__tostring:ExprToString
	}
}
	Items[item.Name] = item
