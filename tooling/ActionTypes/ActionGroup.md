# ActionType - Action Group
ActionGroup is the base **ActionType** in XConfigMaster. It is manly used for grouping certain tasks or closing off the scope. 

It will **Validate**, **Clean**, and **Execute** all inner tasks given the already existing rules on **PreActions** and **PostActions**

### Properties 
- No Properties required
- No Properties allowed

### Parameters 
- No Parameter required
- Any Parameter allowed

### Sections 
- No Parameter required
- No Sections allowed

### Actions 
- 1+ Actions required of any type
- 0+ Preactions required of any type
- 0+ Postactions required of any type
### Usage - .xconfigmaster
```XML
<Action Name="{Action Name}" Type="ActionGroup">
    <!-- Actions that will be executed before any action inside of '{Some Action}' are executed -->
    <PreAction Name="{Some Pre Action}" Type="..."/>
    
    <!-- Any sub actions -->
    <Action Name="{Some Action}" Type="..."/>
    
    <!-- Actions that will be executed after any action inside of '{Some Action}' are executed -->
    <PostAction Name="{Some Post Action}" Type="..."/>
</Action>
```
