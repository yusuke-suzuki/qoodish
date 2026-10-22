'use client';

import EmailOutlined from '@mui/icons-material/EmailOutlined';
import Google from '@mui/icons-material/Google';
import {
  Button,
  Card,
  CardContent,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Typography
} from '@mui/material';
import {
  type AuthError,
  EmailAuthProvider,
  GoogleAuthProvider,
  getAuth,
  linkWithPopup,
  onIdTokenChanged,
  type UserInfo,
  unlink
} from 'firebase/auth';
import { useParams } from 'next/navigation';
import { enqueueSnackbar } from 'notistack';
import { useContext, useEffect, useState } from 'react';
import AuthContext from '../../context/AuthContext.ts';
import useDictionary from '../../hooks/useDictionary.ts';
import LinkEmailDialog from './LinkEmailDialog.tsx';
import UnlinkProviderDialog from './UnlinkProviderDialog.tsx';

function ProvidersCard() {
  const dictionary = useDictionary();
  const { lang } = useParams<{ lang: string }>();
  const { authenticated } = useContext(AuthContext);
  const [providerData, setProviderData] = useState<UserInfo[]>([]);

  useEffect(() => {
    const auth = getAuth();
    const unsubscribe = onIdTokenChanged(auth, (user) => {
      setProviderData([...(user?.providerData ?? [])]);
    });
    return () => unsubscribe();
  }, []);

  const [loading, setLoading] = useState(false);
  const [unlinkDialogOpen, setUnlinkDialogOpen] = useState(false);
  const [unlinkTargetProviderId, setUnlinkTargetProviderId] = useState<
    string | null
  >(null);
  const [linkEmailDialogOpen, setLinkEmailDialogOpen] = useState(false);

  const googleProvider = providerData.find(
    (p) => p.providerId === GoogleAuthProvider.PROVIDER_ID
  );

  const emailProvider = providerData.find(
    (p) => p.providerId === EmailAuthProvider.PROVIDER_ID
  );

  const canUnlink = [googleProvider, emailProvider].filter(Boolean).length > 1;

  const handleLinkGoogle = async () => {
    const firebaseUser = getAuth().currentUser;
    if (!firebaseUser) return;

    setLoading(true);

    try {
      const auth = getAuth();
      auth.languageCode = lang;

      const provider = new GoogleAuthProvider();
      await linkWithPopup(firebaseUser, provider);
      await firebaseUser.reload();
      setProviderData([...firebaseUser.providerData]);

      enqueueSnackbar(dictionary['link provider success'], {
        variant: 'success'
      });
    } catch (error) {
      console.error(error);

      const errorCode = (error as AuthError).code;

      if (errorCode === 'auth/credential-already-in-use') {
        enqueueSnackbar(dictionary['link google error already in use'], {
          variant: 'error'
        });
      } else if (errorCode === 'auth/popup-closed-by-user') {
        enqueueSnackbar(dictionary['link google error popup closed'], {
          variant: 'error'
        });
      } else {
        enqueueSnackbar(dictionary['an error occurred'], {
          variant: 'error'
        });
      }
    } finally {
      setLoading(false);
    }
  };

  const handleOpenUnlinkDialog = (providerId: string) => {
    setUnlinkTargetProviderId(providerId);
    setUnlinkDialogOpen(true);
  };

  const handleUnlink = async () => {
    const firebaseUser = getAuth().currentUser;
    if (!firebaseUser || !unlinkTargetProviderId) return;

    try {
      await unlink(firebaseUser, unlinkTargetProviderId);
      await firebaseUser.reload();
      setProviderData([...firebaseUser.providerData]);

      enqueueSnackbar(dictionary['unlink provider success'], {
        variant: 'success'
      });
    } catch (error) {
      console.error(error);
      enqueueSnackbar(dictionary['an error occurred'], { variant: 'error' });
    }
  };

  return (
    <>
      <Card>
        <CardContent>
          <Typography variant="h5" component="h2" gutterBottom>
            {dictionary['authentication providers']}
          </Typography>
          <Typography component="p" color="text.secondary" gutterBottom>
            {dictionary['authentication providers detail']}
          </Typography>

          <List>
            <ListItem>
              <ListItemIcon>
                <Google />
              </ListItemIcon>
              <ListItemText
                primary={dictionary.google}
                secondary={googleProvider?.email ?? dictionary['not linked']}
                slotProps={{ secondary: { noWrap: true } }}
              />
              {googleProvider ? (
                <Button
                  variant="outlined"
                  color="error"
                  size="small"
                  sx={{ flexShrink: 0 }}
                  onClick={() =>
                    handleOpenUnlinkDialog(GoogleAuthProvider.PROVIDER_ID)
                  }
                  disabled={!canUnlink || loading || !authenticated}
                >
                  {dictionary.unlink}
                </Button>
              ) : (
                <Button
                  variant="outlined"
                  color="secondary"
                  size="small"
                  sx={{ flexShrink: 0 }}
                  onClick={handleLinkGoogle}
                  disabled={loading || !authenticated}
                >
                  {dictionary.link}
                </Button>
              )}
            </ListItem>

            <ListItem>
              <ListItemIcon>
                <EmailOutlined />
              </ListItemIcon>
              <ListItemText
                primary={dictionary['email link provider']}
                secondary={emailProvider?.email ?? dictionary['not linked']}
                slotProps={{ secondary: { noWrap: true } }}
              />
              {emailProvider ? (
                <Button
                  variant="outlined"
                  color="error"
                  size="small"
                  sx={{ flexShrink: 0 }}
                  onClick={() =>
                    handleOpenUnlinkDialog(EmailAuthProvider.PROVIDER_ID)
                  }
                  disabled={!canUnlink || loading || !authenticated}
                >
                  {dictionary.unlink}
                </Button>
              ) : (
                <Button
                  variant="outlined"
                  color="secondary"
                  size="small"
                  sx={{ flexShrink: 0 }}
                  onClick={() => setLinkEmailDialogOpen(true)}
                  disabled={loading || !authenticated}
                >
                  {dictionary.link}
                </Button>
              )}
            </ListItem>
          </List>
        </CardContent>
      </Card>

      <UnlinkProviderDialog
        open={unlinkDialogOpen}
        onClose={() => setUnlinkDialogOpen(false)}
        onUnlink={handleUnlink}
      />

      <LinkEmailDialog
        open={linkEmailDialogOpen}
        onClose={() => setLinkEmailDialogOpen(false)}
      />
    </>
  );
}

export default ProvidersCard;
