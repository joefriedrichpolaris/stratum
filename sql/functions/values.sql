print '
Generating value functions...'


if object_id('[orm].[orm_values]', 'IF') is not null
	drop function [orm].orm_values
go

create function [orm].[orm_values]
(
	@templateName varchar(250)
)
returns table
as
return
(
	-- This is a generic view on the template's values
	--	presented in a format similar to Ignition's historian tables.
	
	select  o.name as Name
		,	p.name as Property

		,	vi.value as IntValue
		,	vf.value as FloatValue
		,	vs.value as StringValue
		,	vd.value as DateValue
		,	vo.value as InstanceValue
	
		,	o.instanceID
		,	p.propertyID
	
	from	orm_meta_instances as o
		inner join orm_meta_properties as p
			on o.templateID = p.templateID

		inner join orm_meta_templates as t 
			on p.templateID = t.templateID

		left join orm_meta_values_integer	as vi
			on	o.instanceID   = vi.instanceID
			and	p.propertyID = vi.propertyID

		left join orm_meta_values_decimal	as vf
			on	o.instanceID   = vf.instanceID
			and	p.propertyID = vf.propertyID

		left join orm_meta_values_string	as vs
			on	o.instanceID   = vs.instanceID
			and	p.propertyID = vs.propertyID

		left join orm_meta_values_datetime	as vd
			on	o.instanceID   = vd.instanceID
			and	p.propertyID = vd.propertyID

		left join orm_meta_values_instance	as vo
			on	o.instanceID   = vo.instanceID
			and	p.propertyID = vo.propertyID
	where t.name = @templateName
)
GO


if object_id('[orm].[orm_values_listing]', 'IF') is not null
	drop function [orm].orm_values_listing
go

create function [orm].[orm_values_listing]
(
	@templateName varchar(250)
)
returns table
as
return
(
	-- This is a view on the template's values where one row per value
	--	and makes the values stringly-typed.
	-- Use this when you want a simple, unified view on the data,
	--	especially when looping over the data.

	select 
			o.name as [Instance]
		,	p.name as Property
		,	isnull(v.value,'') as Value
		,	d.name as Datatype
		,	o.instanceID
		,	p.propertyID
		,	p.datatypeID
	
	from	orm_meta_instances as o
		inner join orm_meta_templates as t
			on o.templateID = t.templateID
		inner join orm_meta_properties as p
			on o.templateID = p.templateID
		inner join orm_meta_templates as d
			on p.datatypeID = d.templateID
		inner join
		(	select instanceID, propertyID, convert(nvarchar(max),value) as value
			from orm_meta_values_integer
			
			union

			select instanceID, propertyID, convert(nvarchar(max),value) as value
			from orm_meta_values_decimal

			union

			select instanceID, propertyID, convert(nvarchar(max),value) as value
			from orm_meta_values_string

			union
						-- convert the datetime to ODBC canonical yyyy-mm-dd hh:mi:ss.mmm
			select instanceID, propertyID, convert(nvarchar(max),value, 121) as value
			from orm_meta_values_datetime

			union

			select instanceID, propertyID, convert(nvarchar(max),value) as value
			from orm_meta_values_instance

		) as v
			on	o.instanceID   = v.instanceID
			and	p.propertyID = v.propertyID
	where t.name = @templateName
)
GO