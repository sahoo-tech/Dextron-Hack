import React, { useState, useEffect } from 'react';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { CssBaseline, Container, Box } from '@mui/material';
import { ethers } from 'ethers';
import Header from './components/Header';
import YieldDashboard from './components/YieldDashboard';
import VerifierInterface from './components/VerifierInterface';
import LoadingOverlay from './components/LoadingOverlay';

const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#2196f3',
    },
    secondary: {
      main: '#f50057',
    },
    background: {
      default: '#121212',
      paper: '#1e1e1e',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
  },
});

function App() {
  const [loading, setLoading] = useState(false);
  const [account, setAccount] = useState('');
  const [provider, setProvider] = useState(null);

  useEffect(() => {
    const initializeEthers = async () => {
      if (window.ethereum) {
        try {
          await window.ethereum.request({ method: 'eth_requestAccounts' });
          const provider = new ethers.providers.Web3Provider(window.ethereum);
          const signer = provider.getSigner();
          const address = await signer.getAddress();
          
          setProvider(provider);
          setAccount(address);
        } catch (error) {
          console.error('Error connecting to MetaMask', error);
        }
      }
    };

    initializeEthers();
  }, []);

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Box
        sx={{
          minHeight: '100vh',
          background: 'linear-gradient(45deg, #1a237e 30%, #0d47a1 90%)',
        }}
      >
        <Header account={account} />
        <Container maxWidth="lg" sx={{ py: 4 }}>
          <YieldDashboard provider={provider} />
          <VerifierInterface provider={provider} setLoading={setLoading} />
        </Container>
        <LoadingOverlay open={loading} />
      </Box>
    </ThemeProvider>
  );
}

export default App;