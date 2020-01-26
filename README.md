DiUS shopping code challenge
===

https://github.com/DiUS/coding-tests/blob/master/dius_shopping.md#example-scenarios

### Adopted Principals
 - Considerations specific to code challenges
   - Flat structure: reduce need to hunt through directory structures (In production environment we would align classes to their directory namespace)
   - Standard library only: simplified setup
   - Minimal code: Demonstrate knowledge of the language (In production environment we might sway more towards verboseness and readability)
   - Simplified interfaces: Rules, and Items are passed in, these will need to be intuitive in order for someone to interact easily

### Setup
Check your ruby version (I am using ruby 2.6.3p62 (2019-04-16 revision 67580) [x86_64-darwin18])
```shell
$ ruby -v
```

Clone this repository
```shell
git clone https://github.com/m8rix/dius_shopping.git ~/m8rix_shopping
```

Run tests
```shell
ruby ~/m8rix_shopping/tests.rb
```

Interact (via irb)
```shell
irb
```
```irb
load "~/m8rix_shopping/shopping.rb"
mbp = Item.new(sku: :mbp, name: "MacBook Pro", price: 1399.99)
ipd = Item.new(sku: :ipd, name: "Super iPad",  price: 549.99)
atv = Item.new(sku: :atv, name: "Apple TV",    price: 109.50)
vga = Item.new(sku: :vga, name: "VGA adapter", price: 30.00)

co = Checkout.new([])
co.scan(mbp)
co.total
```

### Interfaces
  - **Item**
    Create an Item providing three inputs: `sku`, `name`, & `price`
    ```ruby
      Item.new(sku: :mbp, name: "MacBook Pro", price: 1399.99)
    ```
  - **Rule**
    Rules are defined by a hash definition, there are four known keys that are understood by the program:
    - **period** (optional): This is a conditional type, if the condition is met, then the received discount is applied
    - **bulk** (optional): This is a conditional type, if the condition is met, then the received discount is applied
    - **batch** (optional): This is a counter type, received discount is applied proportionally
    - **receive** (required): Must be accompanied by either a batch or a bulk option. This defines what the discount is that will be applied. discount options are:
      - fixed: override the original prices
      - discount: dollar amount to subtract from original prices
      - percent: percentage discount to deduct from original prices
      - *none*:  received item will be free
    ```ruby
      @rules = [
        Rule.new( # Buy 3 atv, get one atv free
          batch:   { sku: :atv, qty: 3 },
          receive: { sku: :atv }
        ),
        Rule.new( # Buy one mbp, get one vga free
          batch:   { sku: :mbp },
          receive: { sku: :vga }
        ),
        Rule.new( # Buy four or more ipd, get all ipd at a fixed price
          bulk:    { sku: :ipd, qty: 4 },
          receive: { sku: :ipd, fixed: 499.99 }
        )
      ]
    ```
    - qty can be ommitted, it will default to 1
 