<template>
  <div class="loading" v-if="loading">
    Loading...
  </div>
  <main class="main">
    <div>
      <h1 class="title">Welcome to Runners Club! #fitdev</h1>
      <div class="description">
        It is an NFT collection of runners in Crypto World
      </div>
      <div class="description">
        {{ tokenIdsMinted }}/20 have been minted
      </div>
      <div>
        <button v-if="!walletConnected" @click="connectWallet" class="button">
          Connect your wallet
        </button>

        <button v-if="isOwner && !presaleStarted" @click="startPresale" class="button">
          Start Presale!
        </button>

        <div v-if="!presaleStarted">
          <div class="description">Presale hasnt started!</div>
        </div>

        <div v-if="presaleStarted && !presaleEnded">
          <div class="description">
            Presale has started!!! If your address is whitelisted, Mint a
            Running Dev 🥳
          </div>
          <button class="button" @click="presaleMint">
            Presale Mint 🚀
          </button>
        </div>
        <div v-if="presaleStarted && presaleEnded">
          <button class="button" @click="publicMint">
            Public Mint 🚀
          </button>
        </div>
      </div>
    </div>
    <div>
      <img class="image" src="./assets/medal_trans.png" />
    </div>
  </main>

  <footer class="footer">
    Made by Yohn Cheung #fitdevs
  </footer>
</template>

<script>
import { Contract, providers, utils } from "ethers";
import Web3Modal from "web3modal"
import { abi, NFT_CONTRACT_ADDRESS } from "./constants";

export default {
  name: "App",
  data() {
    return {
      walletConnected: false,
      presaleStarted: false,
      presaleEnded: false,
      loading: false,
      isOwner: false,
      tokenIdsMinted: 0,
      web3ModalRef: null 
    }
  },
  created() {
    if(!this.walletConnected) {
      this.web3ModalRef = new Web3Modal({
        network: "rinkeby",
        providerOptions: {},
        disableInjectedProvider: false,
      });
      this.connectWallet();

      // Check if presale has started and ended
      const _presaleStarted = this.checkIfPresaleStarted();
      if (_presaleStarted) {
        this.checkIfPresaleEnded();
      }

      this.getTokenIdsMinted();
      // Set an interval which gets called every 5 seconds to check presale has ended
      const presaleEndedInterval = setInterval(async() => {
        const _presaleStarted = await this.checkIfPresaleStarted();
        if (_presaleStarted) {
          const _presaleEnded = await this.checkIfPresaleEnded();
          if (_presaleEnded) {
            clearInterval(presaleEndedInterval);
          }
        }
      }, 5 * 1000);

      // set an interval to get the number of token Ids minted every 5 seconds
      setInterval(async() => {
        await this.getTokenIdsMinted();
      }, 5 * 1000);

    }
  },
  methods: {
    async presaleMint() {
      try {
        const signer = await this.getProviderOrSigner(true)
        const whitelistContract = new Contract(NFT_CONTRACT_ADDRESS, abi, signer)

        const tx = await whitelistContract.presaleMint({
          value: utils.parseEther("0.01")
        })
        this.loading = true;
        await tx.wait();
        this.loading = false
        window.alert("You successfully minted a Running Dev!");
      } catch (error) {
        console.error('error: ', error);
      }
    },
    async publicMint(){
      try {
        const singer = await this.getProviderOrSigner(true)
        const whitelistContract = new Contract(NFT_CONTRACT_ADDRESS, abi, signer)

        const tx = await whitelistContract.mint({value: utils.parseEther("0.001")})

        this.loading = true

        await tx.wait();
        this.loading = false

        window.alert("You successfully minted a Running Dev!");
      } catch (error) {
        console.error('error: ', error);
      }
    },
    async connectWallet() {
      try {
        await this.getProviderOrSigner()
        this.walletConnected = true
      } catch (error) {
        console.log('error: ', error)
      }
    },
    async startPresale() {
      try {
        const signer = await this.getProviderOrSigner(true)

        const whitelistContract= new Contract(NFT_CONTRACT_ADDRESS, abi, signer)
        const tx = await whitelistContract.startPresale();
        this.loading = true;
        await tx.wait();
        this.loading = false;

        await this.checkIfPresaleStarted()
      } catch (error) {
        console.log('error: ', error)
      }
    },
    async checkIfPresaleStarted() {
      try {
        const provider = await this.getProviderOrSigner();

        const nftContract = new Contract(NFT_CONTRACT_ADDRESS, abi, provider);

        const _presaleStarted = await nftContract.presaleStarted();

        if (!_presaleStarted) {
          await this.getOwner();
        }

        this.presaleStarted = _presaleStarted
        return _presaleStarted
      } catch (error) {
        console.error(error);
        return false;
      }
    },
    async checkIfPresaleEnded() {
      try {
        const provider = await this.getProviderOrSigner();

        const nftContract = new Contract(NFT_CONTRACT_ADDRESS, abi, provider);

        const _presaleEnded = await nftContract.presaleEnded();
        // _presaleEnded is a Big Number, so we are using the lt(less than function) instead of `<`
      // Date.now()/1000 returns the current time in seconds
      // We compare if the _presaleEnded timestamp is less than the current time
      // which means presale has ended
        const hasEnded = _presaleEnded.lt(Math.floor(Date.now() / 1000));
        if (hasEnded) {
          this.setPresaleEnded = true
        } else {
          this.setPresaleEnded = false
        }
        return hasEnded;
      } catch (error) {
        console.error(error);
        return false;
      }
    },
    async getOwner() {
      try {
        // Get the provider from web3Modal, which in our case is MetaMask
        // No need for the Signer here, as we are only reading state from the blockchain
        const provider = await this.getProviderOrSigner();
        // We connect to the Contract using a Provider, so we will only
        // have read-only access to the Contract
        const nftContract = new Contract(NFT_CONTRACT_ADDRESS, abi, provider);
        // call the owner function from the contract
        const _owner = await nftContract.owner();
        // We will get the signer now to extract the address of the currently connected MetaMask account
        const signer = await this.getProviderOrSigner(true);
        // Get the address associated to the signer which is connected to  MetaMask
        const address = await signer.getAddress();
        if (address.toLowerCase() === _owner.toLowerCase()) {
          this.isOwner = true
        }
      } catch (err) {
        console.error(err.message);
      }
    },
    async getTokenIdsMinted() {
      try {

        const provider = await this.getProviderOrSigner();

        const nftContract = new Contract(NFT_CONTRACT_ADDRESS, abi, provider);
        // call the tokenIds from the contract
        const _tokenIds = await nftContract.tokenIds();
        //_tokenIds is a `Big Number`. We need to convert the Big Number to a string

        this.tokenIdsMinted = _tokenIds.toString()
       
      } catch (err) {
        console.error(err);
      }
    },
    async getProviderOrSigner(needSigner = false) {
      // Connect to Metamask
      // Since we store `web3Modal` as a reference, we need to access the `current` value to get access to the underlying object
      const provider = await this.web3ModalRef.connect();
      const web3Provider = new providers.Web3Provider(provider);

      // If user is not connected to the Rinkeby network, let them know and throw an error
      const { chainId } = await web3Provider.getNetwork();
      if (chainId !== 4) {
        window.alert("Change the network to Rinkeby");
        throw new Error("Change network to Rinkeby");
      }

      if (needSigner) {
        const signer = web3Provider.getSigner();
        return signer;
      }
      return web3Provider;
    }
    
  }
}
</script>

<style scoped>
.loading {
  width: auto;
  background:#1976d2;
  color: #ffffff;
  margin: 0 auto;
  padding: 1em;
  text-align: center;
  position: absolute;
  left: 0;
  right: 0;
}
</style>
