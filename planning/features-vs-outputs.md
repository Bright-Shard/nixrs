# Features vs Outputs

I've made outputs very powerful and easy to use as dependencies. So I need to make sure there's a clear difference between features and outputs and clear use cases for both. Otherwise they'll confuse new users and could be better merged into one feature.

Right now the thought process is that features allow conditional code within the same crate, so you don't need to rewrite portions of it.

Outputs also allow conditional code but produce completely separate crates.
