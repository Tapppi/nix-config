{inputs, ...}:

let
    nixCats = import './modules/nvim' { inherit inputs; }; in
{
  imports = [
    nixCats.homeModule
  ];
}
