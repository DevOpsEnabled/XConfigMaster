# ActionType - Action Group
ActionGroup is the base **ActionType** in XConfigMaster. It is manly used for grouping certain tasks or closing off the scope. 

It will **Validate**, **Clean**, and **Execute** all inner tasks given the already existing rules on **PreActions** and **PostActions**

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
